param(
    [string]$Serial = ""
)

$adbArgs = @()
if ($Serial) { $adbArgs += @("-s", $Serial) }

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: No se encontro 'adb' en el PATH. Instala Android Platform-Tools y vuelve a intentarlo." -ForegroundColor Red
    exit 1
}

$adbState = (& adb @adbArgs get-state 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0 -or $adbState.Trim() -ne "device") {
    Write-Host "ERROR: No hay un dispositivo ADB autorizado conectado ($($adbState.Trim()))." -ForegroundColor Red
    Write-Host "Activa Depuracion USB y verifica con: adb devices (o usa -Serial <id> si hay varios dispositivos)." -ForegroundColor Yellow
    exit 1
}

$rootCheck = (& adb @adbArgs shell "su -c id" 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0 -or $rootCheck -notmatch "uid=0\(") {
    Write-Host "ERROR: No se obtuvo acceso root via 'adb shell su -c id'." -ForegroundColor Red
    Write-Host "Abre KernelSU Next -> Superusuario y concede permiso root a 'Shell' (com.android.shell, UID 2000)." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Revirtiendo ajustes de sistema y 5G (traced y ahorro 5G) a valores stock ===" -ForegroundColor Yellow

$remoteScript = @'
su -c '
setprop persist.traced.enable 1
start traced 2>/dev/null || true
start traced_probes 2>/dev/null || true
settings delete system power_center_5g_save_mode

echo "Ajustes de sistema y 5G (traced y ahorro 5G) restaurados a stock."
'
'@

$remoteScript -replace "`r", "" | & adb @adbArgs shell sh
if ($LASTEXITCODE -ne 0) {
    Write-Host "El script termino con errores (codigo $LASTEXITCODE). Revisa la salida anterior." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Listo. Reinicia el equipo para aplicar los valores stock." -ForegroundColor Green
Write-Host "Para restaurar apps de sistema: adb shell cmd package install-existing <paquete>" -ForegroundColor Gray
Write-Host "Para apps Xiaomi/Google de /product/data-app/ (Brujula, Escaner, Google News, etc.), consulta la seccion 5.1 de la guia." -ForegroundColor Gray
Write-Host 'Para restablecer ART de una app: adb shell "su -c ''cmd package compile --reset <paquete>''"' -ForegroundColor Gray
