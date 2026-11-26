param(
    [string]$Serial = ""
)

$script:SelectedSerial = $Serial
$script:Script01 = Join-Path $PSScriptRoot "01_limpieza_y_optimizacion_hos4_eea_evonix.ps1"
$script:Script02 = Join-Path $PSScriptRoot "02_revertir_optimizaciones_hos4_eea.ps1"

function Get-AdbArgs {
    if ($script:SelectedSerial) { return @("-s", $script:SelectedSerial) }
    return @()
}

function Read-MenuInput {
    param([string]$Prompt)
    if ([Console]::IsInputRedirected) {
        Write-Host "${Prompt}: " -NoNewline
        $val = [Console]::In.ReadLine()
    } else {
        $val = Read-Host $Prompt
    }
    if ($null -eq $val) { return $null }
    return $val.Trim()
}

function Pause-Return {
    param([string]$Message = "Presiona ENTER para volver al menu principal")
    Write-Host ""
    $null = Read-MenuInput $Message
}

function Confirm-Action {
    param([string]$Prompt = "Deseas continuar? (S/N)")
    $ans = Read-MenuInput $Prompt
    if ($null -eq $ans) { return $false }
    return ($ans -match '^(s|si|y|yes)$')
}

function Get-ConnectedDevices {
    if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { return @() }
    $lines = & adb devices -l 2>$null
    $result = @()
    foreach ($line in $lines) {
        if ($line -match '^(\S+)\s+(device|unauthorized|offline)(.*)$') {
            $result += [PSCustomObject]@{
                Serial = $matches[1]
                State  = $matches[2]
                Info   = $matches[3].Trim()
            }
        }
    }
    return $result
}

function Get-DeviceStatus {
    $status = [ordered]@{
        AdbOk        = $false
        DeviceOk     = $false
        RootOk       = $false
        MultiDevices = $false
        DeviceLabel  = "No conectado"
        ErrorMsg     = ""
    }

    if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
        $status.ErrorMsg = "No se encontro 'adb' en el PATH (instala Android Platform-Tools)."
        return [PSCustomObject]$status
    }
    $status.AdbOk = $true

    $devices = @(Get-ConnectedDevices)
    $readyDevices = @($devices | Where-Object { $_.State -eq "device" })

    if ($script:SelectedSerial) {
        $match = $devices | Where-Object { $_.Serial -eq $script:SelectedSerial } | Select-Object -First 1
        if (-not $match -or $match.State -ne "device") {
            $status.DeviceLabel = "Serial seleccionado no disponible"
            $status.ErrorMsg = "El dispositivo seleccionado ('$($script:SelectedSerial)') no esta listo en ADB."
            return [PSCustomObject]$status
        }
    } else {
        if ($readyDevices.Count -eq 0) {
            if ($devices.Count -gt 0) {
                $status.DeviceLabel = "Pendiente ($($devices[0].State))"
                $status.ErrorMsg = "Dispositivo detectado en estado '$($devices[0].State)'. Acepta la depuracion USB en la pantalla del telefono."
            } else {
                $status.ErrorMsg = "No hay ningun dispositivo conectado por ADB."
            }
            return [PSCustomObject]$status
        }
        if ($readyDevices.Count -gt 1) {
            $status.MultiDevices = $true
            $status.DeviceLabel = "$($readyDevices.Count) dispositivos (usa opcion D)"
            $status.ErrorMsg = "Hay $($readyDevices.Count) dispositivos ADB conectados. Selecciona uno en la opcion D."
            return [PSCustomObject]$status
        }
    }

    $adbArgs = Get-AdbArgs
    $model = ((& adb @adbArgs shell "getprop ro.product.model" 2>$null) -join "").Trim()
    if (-not $model) { $model = "Android" }
    $status.DeviceOk = $true
    $status.DeviceLabel = if ($script:SelectedSerial) { "$model [serial activo]" } else { $model }

    $rootOut = (& adb @adbArgs shell "su -c id" 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0 -and $rootOut -match "uid=0\(") {
        $status.RootOk = $true
    } else {
        $status.ErrorMsg = "No se obtuvo root en 'Shell'. Abre KernelSU Next -> Superusuario y activa root para Shell (UID 2000)."
    }

    return [PSCustomObject]$status
}

function Assert-Ready {
    param([switch]$RequireRoot)
    $st = Get-DeviceStatus
    if (-not $st.AdbOk -or -not $st.DeviceOk) {
        Write-Host ""
        Write-Host "ERROR: $($st.ErrorMsg)" -ForegroundColor Red
        return $false
    }
    if ($RequireRoot -and -not $st.RootOk) {
        Write-Host ""
        Write-Host "ERROR: $($st.ErrorMsg)" -ForegroundColor Red
        return $false
    }
    return $true
}

function Show-Header {
    param([object]$Status)
    try { Clear-Host } catch {}
    Write-Host "+======================================================================+" -ForegroundColor Cyan
    Write-Host "|   HyperOS 4 EEA (OS4.0.1.0 / Android 17) + Kernel EVONIX 4.6.1       |" -ForegroundColor Cyan
    Write-Host "|   Menu Interactivo - POCO X7 Pro (rodin_eea)                         |" -ForegroundColor Cyan
    Write-Host "+======================================================================+" -ForegroundColor Cyan

    Write-Host "  ADB: " -NoNewline -ForegroundColor Gray
    if ($Status.AdbOk) { Write-Host "OK" -NoNewline -ForegroundColor Green } else { Write-Host "NO ENCONTRADO" -NoNewline -ForegroundColor Red }

    Write-Host "  |  Dispositivo: " -NoNewline -ForegroundColor Gray
    if ($Status.DeviceOk) { Write-Host $Status.DeviceLabel -NoNewline -ForegroundColor Green } else { Write-Host $Status.DeviceLabel -NoNewline -ForegroundColor Yellow }

    Write-Host "  |  Root Shell: " -NoNewline -ForegroundColor Gray
    if ($Status.RootOk) { Write-Host "OK" -ForegroundColor Green } else { Write-Host "NO" -ForegroundColor Red }

    if ($Status.ErrorMsg) {
        Write-Host "  Aviso: $($Status.ErrorMsg)" -ForegroundColor Yellow
    }
    Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
}

function Invoke-Script01 {
    param(
        [switch]$SkipExtraHos4,
        [switch]$RemoveGetApps,
        [switch]$SkipArtCompile,
        [switch]$OnlyArtCompile,
        [switch]$CompileUserApps,
        [switch]$OnlyFixRustLauncherPoco
    )
    if (-not (Test-Path $script:Script01)) {
        Write-Host "ERROR: No se encontro el script: $($script:Script01)" -ForegroundColor Red
        return
    }
    if (-not (Assert-Ready -RequireRoot)) { return }

    $params = @{}
    if ($script:SelectedSerial)   { $params["Serial"] = $script:SelectedSerial }
    if ($SkipExtraHos4)           { $params["SkipExtraHos4"] = $true }
    if ($RemoveGetApps)           { $params["RemoveGetApps"] = $true }
    if ($SkipArtCompile)          { $params["SkipArtCompile"] = $true }
    if ($OnlyArtCompile)          { $params["OnlyArtCompile"] = $true }
    if ($CompileUserApps)         { $params["CompileUserApps"] = $true }
    if ($OnlyFixRustLauncherPoco) { $params["OnlyFixRustLauncherPoco"] = $true }

    Write-Host ""
    & $script:Script01 @params
}

function Invoke-Script02 {
    if (-not (Test-Path $script:Script02)) {
        Write-Host "ERROR: No se encontro el script: $($script:Script02)" -ForegroundColor Red
        return
    }
    if (-not (Assert-Ready -RequireRoot)) { return }

    $params = @{}
    if ($script:SelectedSerial) { $params["Serial"] = $script:SelectedSerial }

    Write-Host ""
    & $script:Script02 @params
}

function Show-DeviceDiagnostics {
    if (-not (Assert-Ready -RequireRoot)) { return }
    $adbArgs = Get-AdbArgs
    Write-Host ""
    Write-Host "=== Estado actual del dispositivo ===" -ForegroundColor Cyan

    $diagScript = @'
su -c '
echo "Modelo       : $(getprop ro.product.model) ($(getprop ro.product.name))"
echo "ROM          : $(getprop ro.build.version.incremental) (Android $(getprop ro.build.version.release), SDK $(getprop ro.build.version.sdk), parche $(getprop ro.build.version.security_patch))"
echo "Kernel       : $(uname -r)"
echo "SELinux      : $(getenforce 2>/dev/null || echo desconocido) | VBoot=$(getprop ro.boot.verifiedbootstate) | Lock=$(getprop ro.boot.flash.locked)"
echo "traced       : persist.traced.enable=$(getprop persist.traced.enable) | servicio=$(getprop init.svc.traced)"
echo "Ahorro 5G    : power_center_5g_save_mode=$(settings get system power_center_5g_save_mode)"
echo "I/O y Red    : io=$(cat /sys/block/sda/queue/scheduler 2>/dev/null) | tcp=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)"
echo "Rol HOME     : $(cmd role get-role-holders --user 0 android.app.role.HOME 2>/dev/null) (prop=$(getprop ro.miui.product.home))"
echo "Rol DIALER   : $(cmd role get-role-holders --user 0 android.app.role.DIALER 2>/dev/null)"
echo "Rol SMS      : $(cmd role get-role-holders --user 0 android.app.role.SMS 2>/dev/null)"
echo "Servicios MTK:"
for p in com.mediatek.voicecommand com.mediatek.voiceunlock; do
  if pm list packages -d | grep -q "^package:${p}$"; then
    echo "  - $p : DESHABILITADO"
  elif pm path "$p" >/dev/null 2>&1; then
    echo "  - $p : HABILITADO"
  else
    echo "  - $p : NO PRESENTE"
  fi
done
user_cnt=$(pm list packages -3 2>/dev/null | wc -l | tr -d " ")
sys_cnt=$(pm list packages -s 2>/dev/null | wc -l | tr -d " ")
echo "Paquetes     : $user_cnt en /data (-3) | $sys_cnt en sistema (-s)"
if [ -d /data/adb/modules ]; then
  mod_total=0; mod_on=0
  for d in /data/adb/modules/*; do
    [ -d "$d" ] || continue
    mod_total=$((mod_total+1))
    if [ ! -f "$d/disable" ] && [ ! -f "$d/remove" ]; then mod_on=$((mod_on+1)); fi
  done
  echo "Modulos KSU  : $mod_on activos de $mod_total instalados"
fi
'
'@
    $diagScript -replace "`r", "" | & adb @adbArgs shell sh
}

function Show-RestoreSubmenu {
    while ($true) {
        $st = Get-DeviceStatus
        Show-Header -Status $st
        Write-Host ""
        Write-Host " [SUBMENU: RESTAURAR APPS, SERVICIOS MTK Y ART]" -ForegroundColor Yellow
        Write-Host "  1) Restaurar app de sistema (cmd package install-existing <paquete>)"
        Write-Host "  2) Restaurar app de /product/data-app/ (lista numerada automatica)"
        Write-Host "  3) Rehabilitar los 2 servicios MediaTek de voz (voicecommand, voiceunlock)"
        Write-Host "  4) Restablecer compilacion ART de una app (compile --reset)"
        Write-Host "  0) Volver al menu principal"
        Write-Host ""
        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
        $sub = Read-MenuInput "Selecciona una opcion"
        if ($null -eq $sub) { return }

        switch ($sub) {
            "1" {
                $ran = $false
                if (Assert-Ready) {
                    Write-Host ""
                    Write-Host "Ejemplos: com.xiaomi.aicr | com.android.chrome | com.google.android.dialer" -ForegroundColor Gray
                    $pkg = Read-MenuInput "Ingresa el nombre exacto del paquete (ENTER para cancelar)"
                    if ($pkg) {
                        $ran = $true
                        if ($pkg -notmatch '^[A-Za-z0-9_.]+$') {
                            Write-Host "Nombre de paquete invalido." -ForegroundColor Red
                        } else {
                            $adbArgs = Get-AdbArgs
                            Write-Host "Restaurando $pkg ..." -ForegroundColor Cyan
                            & adb @adbArgs shell cmd package install-existing $pkg
                        }
                    }
                } else {
                    $ran = $true
                }
                if ($ran) { Pause-Return "Presiona ENTER para volver al submenu de restauracion" }
            }
            "2" {
                $ran = $false
                if (Assert-Ready -RequireRoot) {
                    $adbArgs = Get-AdbArgs
                    Write-Host ""
                    Write-Host "Consultando /product/data-app/ en el dispositivo..." -ForegroundColor Cyan
                    $rawFolders = & adb @adbArgs shell "su -c 'ls -1 /product/data-app/'" 2>&1
                    $folders = @($rawFolders | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -match '^[A-Za-z0-9_.\-]+$' } | Sort-Object)

                    if ($folders.Count -eq 0) {
                        Write-Host "No se encontraron carpetas en /product/data-app/." -ForegroundColor Yellow
                        $ran = $true
                    } else {
                        Write-Host ""
                        Write-Host "APKs originales disponibles en la ROM:" -ForegroundColor Green
                        for ($i = 0; $i -lt $folders.Count; $i++) {
                            Write-Host ("  {0,2}) {1}" -f ($i + 1), $folders[$i])
                        }
                        Write-Host "   0) Cancelar"
                        Write-Host ""
                        $pick = Read-MenuInput "Elige el numero de la app a restaurar"
                        $idx = 0
                        if ($pick -and [int]::TryParse($pick, [ref]$idx) -and $idx -ge 1 -and $idx -le $folders.Count) {
                            $ran = $true
                            $folder = $folders[$idx - 1]
                            $rawApks = & adb @adbArgs shell "su -c 'ls -1 /product/data-app/$folder/'" 2>&1
                            $apk = @($rawApks | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -match '^[A-Za-z0-9_.\-]+\.apk$' }) | Select-Object -First 1
                            if (-not $apk) {
                                Write-Host "No se encontro ningun archivo .apk dentro de /product/data-app/$folder/." -ForegroundColor Red
                            } else {
                                Write-Host "Instalando $folder/$apk ..." -ForegroundColor Cyan
                                $installCmd = "su -c 'cp /product/data-app/$folder/$apk /data/local/tmp/restore_app.apk && chmod 644 /data/local/tmp/restore_app.apk && (pm install /data/local/tmp/restore_app.apk; rc=`$?; rm -f /data/local/tmp/restore_app.apk; exit `$rc)'"
                                $installOut = & adb @adbArgs shell $installCmd 2>&1
                                $installRc = $LASTEXITCODE
                                $installOut | ForEach-Object { Write-Host $_ }
                                if ($installRc -eq 0 -and (($installOut -join "`n") -match "Success")) {
                                    Write-Host "App restaurada correctamente." -ForegroundColor Green
                                } else {
                                    Write-Host "No se pudo completar la instalacion (codigo $installRc)." -ForegroundColor Red
                                }
                            }
                        } elseif ($pick -and $pick -ne "0") {
                            $ran = $true
                            Write-Host "Seleccion fuera de rango." -ForegroundColor Yellow
                        }
                    }
                } else {
                    $ran = $true
                }
                if ($ran) { Pause-Return "Presiona ENTER para volver al submenu de restauracion" }
            }
            "3" {
                if (Assert-Ready -RequireRoot) {
                    $adbArgs = Get-AdbArgs
                    Write-Host ""
                    Write-Host "Rehabilitando servicios MediaTek de voz..." -ForegroundColor Cyan
                    & adb @adbArgs shell "su -c 'pm enable com.mediatek.voicecommand && pm enable com.mediatek.voiceunlock'"
                }
                Pause-Return "Presiona ENTER para volver al submenu de restauracion"
            }
            "4" {
                $ran = $false
                if (Assert-Ready -RequireRoot) {
                    Write-Host ""
                    $pkg = Read-MenuInput "Ingresa el nombre exacto del paquete para restablecer ART (ENTER para cancelar)"
                    if ($pkg) {
                        $ran = $true
                        if ($pkg -notmatch '^[A-Za-z0-9_.]+$') {
                            Write-Host "Nombre de paquete invalido." -ForegroundColor Red
                        } else {
                            $adbArgs = Get-AdbArgs
                            Write-Host "Restableciendo perfil ART de $pkg ..." -ForegroundColor Cyan
                            & adb @adbArgs shell "su -c 'cmd package compile --reset $pkg'"
                        }
                    }
                } else {
                    $ran = $true
                }
                if ($ran) { Pause-Return "Presiona ENTER para volver al submenu de restauracion" }
            }
            "0" { return }
            default {
                Write-Host "Opcion no valida." -ForegroundColor Yellow
                Start-Sleep -Milliseconds 900
            }
        }
    }
}

function Select-AdbDevice {
    Write-Host ""
    if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: No se encontro 'adb' en el PATH." -ForegroundColor Red
        return
    }
    $devices = @(Get-ConnectedDevices)
    if ($devices.Count -eq 0) {
        Write-Host "No hay dispositivos conectados en 'adb devices'." -ForegroundColor Yellow
        $script:SelectedSerial = ""
        return
    }

    Write-Host "Dispositivos ADB detectados:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $devices.Count; $i++) {
        $mark = if ($script:SelectedSerial -eq $devices[$i].Serial) { " [ACTUAL]" } else { "" }
        Write-Host ("  {0}) {1} ({2}) {3}{4}" -f ($i + 1), $devices[$i].Serial, $devices[$i].State, $devices[$i].Info, $mark)
    }
    Write-Host "  A) Automatico (sin fijar serial)"
    Write-Host "  0) Cancelar"
    Write-Host ""
    $pick = Read-MenuInput "Selecciona una opcion"
    if ($null -eq $pick) { return }
    if ($pick -match '^[Aa]$') {
        $script:SelectedSerial = ""
        Write-Host "Modo automatico activado." -ForegroundColor Green
        return
    }
    $idx = 0
    if ([int]::TryParse($pick, [ref]$idx) -and $idx -ge 1 -and $idx -le $devices.Count) {
        $script:SelectedSerial = $devices[$idx - 1].Serial
        Write-Host "Dispositivo seleccionado: $($script:SelectedSerial)" -ForegroundColor Green
    }
}

while ($true) {
    $status = Get-DeviceStatus
    Show-Header -Status $status

    Write-Host ""
    Write-Host " [PASO 1: LIMPIEZA INICIAL - HYPEROS 4 EEA]" -ForegroundColor Yellow
    Write-Host "  1) Limpieza completa (125 apps + GetApps opcional) + Ajustes SIN ART"
    Write-Host "     (Recomendado primero, antes de instalar modulos KSU y tus apps)" -ForegroundColor DarkGray
    Write-Host "  2) Limpieza completa (125 apps + GetApps opcional) + Ajustes + ART core"
    Write-Host "     (Si no vas a instalar modulos KSU despues)" -ForegroundColor DarkGray
    Write-Host "  3) Limpieza base sin Bloque 4 HOS4 (118 apps + GetApps opcional) + ART"
    Write-Host "     (Conserva AICore, Google Calendar, FederatedCompute, YGPS, etc.)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " [PASO 2: POST-MODULOS KSU Y COMPILACION ART SPEED FINAL]" -ForegroundColor Cyan
    Write-Host "  4) Arreglar HyperOS 4 Rust Launcher Mod para POCO (hyperos_rust_launcher_mod)"
    Write-Host "     (Agrega system.prop, whiteout MiLauncherGlobal y FINDER_ACCESS Android 17)" -ForegroundColor DarkGray
    Write-Host "  5) Compilar ART speed: apps core + todas tus apps de usuario (-3)"
    Write-Host "     (NO desinstala nada; ejecutar al final tras instalar mods y tus apps)" -ForegroundColor DarkGray
    Write-Host "  6) Compilar ART speed: solo apps core de interfaz y modulos"
    Write-Host ""
    Write-Host " [RESTAURACION, REVERSION Y DIAGNOSTICO]" -ForegroundColor Green
    Write-Host "  7) Restaurar apps desinstaladas / servicios MTK / restablecer ART"
    Write-Host "  8) Revertir ajustes de sistema y 5G (traced y ahorro 5G) a stock"
    Write-Host "  9) Ver estado actual del dispositivo (ROM, kernel, modulos, roles, MTK)"
    Write-Host "  D) Seleccionar dispositivo ADB (si hay mas de uno conectado)"
    Write-Host "  R) Actualizar estado de conexion ADB / Root"
    Write-Host "  0) Salir"
    Write-Host ""
    Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray

    $choice = Read-MenuInput "Selecciona una opcion"
    if ($null -eq $choice) { break }

    switch ($choice.ToUpperInvariant()) {
        "1" {
            Write-Host ""
            Write-Host "ATENCION: Eliminara 125 apps (incluyendo Chrome, Mi Browser, Gmail, Maps," -ForegroundColor Yellow
            Write-Host "YouTube, Fotos, Google News, Google Calendar y apps comerciales) y aplicara" -ForegroundColor Yellow
            Write-Host "los ajustes de sistema/5G dejando ART pendiente para despues de tus modulos." -ForegroundColor Yellow
            if (Confirm-Action "Deseas ejecutar la limpieza completa SIN compilar ART? (S/N)") {
                $rmGetApps = Confirm-Action "Deseas eliminar tambien GetApps (com.xiaomi.mipicks)? (S = eliminar / N = conservar para actualizar apps del sistema)"
                if ($rmGetApps) { Invoke-Script01 -SkipArtCompile -RemoveGetApps } else { Invoke-Script01 -SkipArtCompile }
            } else {
                Write-Host "Operacion cancelada." -ForegroundColor Gray
            }
            Pause-Return
        }
        "2" {
            Write-Host ""
            Write-Host "ATENCION: Eliminara 125 apps (incluyendo Chrome, Mi Browser, Gmail, Maps," -ForegroundColor Yellow
            Write-Host "YouTube, Fotos, Google News, Google Calendar y apps comerciales) y compilara" -ForegroundColor Yellow
            Write-Host "ART speed en las apps core. Telefono/Mensajes Google se conservan por defecto." -ForegroundColor Yellow
            if (Confirm-Action "Deseas ejecutar la limpieza completa + ART core? (S/N)") {
                $rmGetApps = Confirm-Action "Deseas eliminar tambien GetApps (com.xiaomi.mipicks)? (S = eliminar / N = conservar para actualizar apps del sistema)"
                if ($rmGetApps) { Invoke-Script01 -RemoveGetApps } else { Invoke-Script01 }
            } else {
                Write-Host "Operacion cancelada." -ForegroundColor Gray
            }
            Pause-Return
        }
        "3" {
            Write-Host ""
            Write-Host "ATENCION: Eliminara 118 apps (bloques base, omitiendo los 7 paquetes extra" -ForegroundColor Yellow
            Write-Host "de HOS4 EEA como AICore y Google Calendar) y compilara ART speed en apps core." -ForegroundColor Yellow
            if (Confirm-Action "Deseas ejecutar la limpieza base (118 apps) + ART core? (S/N)") {
                $rmGetApps = Confirm-Action "Deseas eliminar tambien GetApps (com.xiaomi.mipicks)? (S = eliminar / N = conservar para actualizar apps del sistema)"
                if ($rmGetApps) { Invoke-Script01 -SkipExtraHos4 -RemoveGetApps } else { Invoke-Script01 -SkipExtraHos4 }
            } else {
                Write-Host "Operacion cancelada." -ForegroundColor Gray
            }
            Pause-Return
        }
        "4" {
            Write-Host ""
            Write-Host "Esta opcion parchea el modulo instalado hyperos_rust_launcher_mod para POCO:" -ForegroundColor Yellow
            Write-Host "  - Crea system.prop con ro.miui.product.home=com.miui.home" -ForegroundColor Yellow
            Write-Host "  - Oculta /product/priv-app/MiLauncherGlobal via whiteout (no destructivo)" -ForegroundColor Yellow
            Write-Host "  - Agrega FINDER_ACCESS a privapp-permissions-com.miui.home-mod.xml (Android 17)" -ForegroundColor Yellow
            Write-Host "  - Limpia la cache de escaneo de MiuiHome y MiLauncherGlobal" -ForegroundColor Yellow
            Write-Host "Todo queda dentro del modulo (desactivarlo en KernelSU Next restaura POCO Launcher)." -ForegroundColor Gray
            if (Confirm-Action "Ya instalaste hyperos_rust_launcher_mod (y DisableApkVerification) en KernelSU Next? (S/N)") {
                Invoke-Script01 -OnlyFixRustLauncherPoco
            } else {
                Write-Host "Operacion cancelada." -ForegroundColor Gray
            }
            Pause-Return
        }
        "5" {
            Invoke-Script01 -OnlyArtCompile -CompileUserApps
            Pause-Return
        }
        "6" {
            Invoke-Script01 -OnlyArtCompile
            Pause-Return
        }
        "7" {
            Show-RestoreSubmenu
        }
        "8" {
            Write-Host ""
            Write-Host "Esta opcion restaurara persist.traced.enable=1 y eliminara power_center_5g_save_mode." -ForegroundColor Yellow
            if (Confirm-Action "Deseas revertir estos ajustes a valores stock? (S/N)") {
                Invoke-Script02
            } else {
                Write-Host "Operacion cancelada." -ForegroundColor Gray
            }
            Pause-Return
        }
        "9" {
            Show-DeviceDiagnostics
            Pause-Return
        }
        "D" {
            Select-AdbDevice
            Pause-Return
        }
        "R" {
            # Vuelve al inicio del bucle para refrescar el estado en la cabecera
        }
        "0" {
            Write-Host ""
            Write-Host "Saliendo del menu. Hasta pronto!" -ForegroundColor Cyan
            break
        }
        default {
            Write-Host ""
            Write-Host "Opcion no valida. Elige una opcion del menu (0-9, D o R)." -ForegroundColor Yellow
            Pause-Return
        }
    }

    if ($choice -eq "0") { break }
}

exit 0
