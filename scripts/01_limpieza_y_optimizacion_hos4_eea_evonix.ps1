param(
    [string]$Serial = "",
    [switch]$SkipExtraHos4,
    [switch]$RemoveGetApps,
    [switch]$SkipArtCompile,
    [switch]$OnlyArtCompile,
    [switch]$CompileUserApps,
    [switch]$OnlyFixRustLauncherPoco
)

$adbArgs = @()
if ($Serial) { $adbArgs += @("-s", $Serial) }

if ($OnlyArtCompile -and $OnlyFixRustLauncherPoco) {
    Write-Host "ERROR: No combines -OnlyArtCompile y -OnlyFixRustLauncherPoco en la misma ejecucion." -ForegroundColor Red
    exit 1
}

if ($OnlyArtCompile -and $SkipArtCompile -and -not $CompileUserApps) {
    Write-Host "Aviso: Con -OnlyArtCompile y -SkipArtCompile sin -CompileUserApps no hay tareas por ejecutar." -ForegroundColor Yellow
    exit 0
}

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

if ($OnlyFixRustLauncherPoco) {
    Write-Host "=== HyperOS 4 EEA (OS4.0.1.0) - Fix HyperOS 4 Rust Launcher Mod para POCO ===" -ForegroundColor Cyan
} elseif ($OnlyArtCompile) {
    Write-Host "=== HyperOS 4 EEA (OS4.0.1.0) + EVONIX 4.6.1 - Solo Compilacion ART speed ===" -ForegroundColor Cyan
} else {
    Write-Host "=== HyperOS 4 EEA (OS4.0.1.0) + EVONIX 4.6.1 - Limpieza y Optimizacion Activa ===" -ForegroundColor Cyan
}

$onlyFixLchFlag   = if ($OnlyFixRustLauncherPoco) { "1" } else { "0" }
$onlyArtFlag      = if ($OnlyArtCompile) { "1" } else { "0" }
$extraHos4Flag    = if ($SkipExtraHos4) { "0" } else { "1" }
$removeGetAppsFlg = if ($RemoveGetApps) { "1" } else { "0" }
$artFlag          = if ($SkipArtCompile -or $OnlyFixRustLauncherPoco) { "0" } else { "1" }
$userArtFlag      = if ($CompileUserApps -and -not $OnlyFixRustLauncherPoco) { "1" } else { "0" }

$header = "su -c '`nONLY_FIX_LAUNCHER=$onlyFixLchFlag`nONLY_ART=$onlyArtFlag`nDO_EXTRA_HOS4=$extraHos4Flag`nDO_REMOVE_GETAPPS=$removeGetAppsFlg`nDO_ART=$artFlag`nDO_USER_ART=$userArtFlag`n"

$body = @'
if [ "$ONLY_FIX_LAUNCHER" = "1" ]; then
  echo "=== FIX HYPEROS 4 RUST LAUNCHER MOD (hyperos_rust_launcher_mod) PARA POCO ==="
  found=0
  for MOD in /data/adb/modules/hyperos_rust_launcher_mod /data/adb/modules_update/hyperos_rust_launcher_mod; do
    [ -d "$MOD" ] || continue
    if [ ! -f "$MOD/system/product/priv-app/MiuiHome/MiuiHome.apk" ]; then
      echo "ERROR: Se encontro $MOD pero falta system/product/priv-app/MiuiHome/MiuiHome.apk. Abortando para no ocultar POCO Launcher."
      exit 1
    fi
    found=$((found+1))
    echo "Parcheando modulo en: $MOD"

    # 1. Fijar ro.miui.product.home=com.miui.home en system.prop (conservando otras propiedades)
    SPROP="$MOD/system.prop"
    if [ -f "$SPROP" ]; then
      if grep -q "^ro\.miui\.product\.home=" "$SPROP"; then
        TMP_SP="${SPROP}.tmp"
        : > "$TMP_SP"
        while IFS= read -r line || [ -n "$line" ]; do
          case "$line" in
            ro.miui.product.home=*) printf "ro.miui.product.home=com.miui.home\n" >> "$TMP_SP" ;;
            *) printf "%s\n" "$line" >> "$TMP_SP" ;;
          esac
        done < "$SPROP"
        mv -f "$TMP_SP" "$SPROP"
      else
        printf "ro.miui.product.home=com.miui.home\n" >> "$SPROP"
      fi
    else
      printf "ro.miui.product.home=com.miui.home\n" > "$SPROP"
    fi
    chmod 0644 "$SPROP"
    chown root:root "$SPROP"
    echo "  OK: system.prop -> ro.miui.product.home=com.miui.home"

    # 2. Ocultar /product/priv-app/MiLauncherGlobal via whiteout para que PKMSImpl no ignore MiuiHome en POCO
    WO_TARGET="$MOD/system/product/priv-app/MiLauncherGlobal"
    rm -rf "$WO_TARGET"
    if [ -d /data/adb/modules/hybrid_mount ] && [ ! -f /data/adb/modules/hybrid_mount/disable ] && [ ! -f /data/adb/modules/hybrid_mount/remove ]; then
      mkdir -p "$WO_TARGET"
      : > "$WO_TARGET/.remove"
      chmod 0755 "$WO_TARGET"
      chmod 0644 "$WO_TARGET/.remove"
      chown -R root:root "$WO_TARGET"
      echo "  OK: Whiteout Hybrid-Mount creado ($WO_TARGET/.remove)"
    else
      mknod "$WO_TARGET" c 0 0
      chmod 0000 "$WO_TARGET"
      chown root:root "$WO_TARGET"
      echo "  OK: Whiteout OverlayFS estandar creado (mknod c 0 0 en $WO_TARGET)"
    fi

    # 3. Asegurar FINDER_ACCESS (signature|privileged en Android 17) en privapp-permissions-com.miui.home-mod.xml
    XML="$MOD/system/product/etc/permissions/privapp-permissions-com.miui.home-mod.xml"
    if [ -f "$XML" ]; then
      if ! grep -q "com.mi.appfinder.normal.permission.FINDER_ACCESS" "$XML"; then
        TMP_XML="${XML}.tmp"
        : > "$TMP_XML"
        while IFS= read -r line || [ -n "$line" ]; do
          case "$line" in
            *"</privapp-permissions>"*)
              printf "        <permission name=\"com.mi.appfinder.normal.permission.FINDER_ACCESS\" />\n" >> "$TMP_XML"
              ;;
          esac
          printf "%s\n" "$line" >> "$TMP_XML"
        done < "$XML"
        mv -f "$TMP_XML" "$XML"
        echo "  OK: FINDER_ACCESS agregado a privapp-permissions-com.miui.home-mod.xml"
      else
        echo "  OK: FINDER_ACCESS ya estaba presente en privapp-permissions-com.miui.home-mod.xml"
      fi
      chmod 0644 "$XML"
      chown root:root "$XML"
    else
      echo "  AVISO: No se encontro $XML; verifica que el modulo incluya su allowlist privapp."
    fi
  done

  if [ "$found" -eq 0 ]; then
    echo "ERROR: No se encontro el modulo hyperos_rust_launcher_mod en /data/adb/modules ni en /data/adb/modules_update."
    echo "Instala primero HyperOS 4 Launcher Mod (Rust/Flutter) en KernelSU Next y vuelve a ejecutar esta opcion."
    exit 1
  fi

  # 4. Aviso no bloqueante sobre DisableApkVerification
  if [ ! -d /data/adb/modules/DisableApkVerification ] && [ ! -d /data/adb/modules_update/DisableApkVerification ]; then
    echo "  AVISO: No se detecto el modulo DisableApkVerification. Este mod suele requerir parche de verificacion de firmas."
  fi

  # 5. Limpiar cache de escaneo de PackageManager para MiuiHome y MiLauncherGlobal
  cleared=0
  for f in /data/system/package_cache/*/*; do
    case "$f" in
      *MiuiHome-*|*MiLauncherGlobal-*)
        rm -f "$f" && cleared=$((cleared+1)) && echo "  OK: Cache limpiado -> $f"
        ;;
    esac
  done
  echo "LAUNCHER_FIX_OK=1 MODS_PATCHED=$found CACHE_CLEARED=$cleared"
  exit 0
fi

if [ "$ONLY_ART" = "0" ]; then
  echo "=== 1. REVOCACIONES PREVIAS Y BLOQUEO OTA (MSA Y ACTUALIZADOR) ==="
  settings put secure privacy_status_com.miui.msa.global 0
  settings put secure miui_updater_enable 0
  settings put global ota_disable_automatic_update 1

  run_data() {
    label="$1"; shift
    ok=0; fail=0
    for pkg in "$@"; do
      res=$(pm uninstall "$pkg" 2>&1)
      if echo "$res" | grep -q "Success"; then
        ok=$((ok+1))
      else
        res2=$(pm uninstall --user 0 "$pkg" 2>&1)
        if echo "$res2" | grep -q "Success"; then ok=$((ok+1)); else fail=$((fail+1)); echo "  SKIP/FAIL: $pkg"; fi
      fi
    done
    echo "${label}_OK=$ok ${label}_FAIL=$fail"
  }

  run_sys() {
    label="$1"; shift
    ok=0; fail=0
    for pkg in "$@"; do
      res=$(pm uninstall --user 0 "$pkg" 2>&1)
      if echo "$res" | grep -q "Success"; then ok=$((ok+1)); else fail=$((fail+1)); echo "  SKIP/FAIL: $pkg"; fi
    done
    echo "${label}_OK=$ok ${label}_FAIL=$fail"
  }

  echo "=== 2. APPS PREINSTALADAS EN /cust Y /product/data-app/ (30 apps) ==="
  run_data "DATA_BLOAT" \
    com.block.juggle com.block.puzzle.game.hippo.mi com.jewelsblast.ivygames.Adventure.free \
    com.logame.eliminateintruder3d com.mintgames.triplecrush.tile.fun com.mintgames.wordtrip \
    com.nf.snake com.ordinaryjoy.woodblast com.sukhavati.gotoplaying.bubble.BubbleShooter.mint \
    cn.wps.moffice_eng cn.wps.xiaomi.abroad.lite com.booking com.einnovation.temu \
    com.linkedin.android com.netflix.mediaclient com.spotify.music \
    com.facebook.katana com.zhiliaoapp.musically \
    com.mi.global.pocobbs com.mi.global.shop com.miui.android.fashiongallery \
    com.miui.huanji com.xiaomi.smarthome com.duokan.phone.remotecontroller \
    com.miui.compass com.miui.notes com.miui.weather2 com.xiaomi.midrop com.xiaomi.scanner \
    com.google.android.apps.magazines

  echo "=== 3. PAQUETES DE SISTEMA BASE, TELEMETRIA Y APPS OPCIONALES (88 sistema) ==="
  run_sys "SYS_BLOAT" \
    com.miui.msa.global com.miui.analytics com.miui.misightservice com.miui.bugreport \
    com.miui.miservice com.miui.thirdappassistant com.bsp.catchlog com.debug.loggerui \
    com.android.traceur com.android.devicediagnostics com.wdstechnology.android.kryten \
    android.autoinstalls.config.Xiaomi.model com.mediatek.lbs.em2.ui com.mediatek.mdmconfig \
    com.mediatek.mdmlsample com.mediatek.atmwifimeta com.jiiov.fingerprint_factorytest \
    com.android.updater com.xiaomi.discover com.mi.appfinder \
    com.mi.globalminusscreen com.mi.globalbrowser com.mi.healthglobal com.miui.cleaner \
    com.miui.phrase com.miui.player com.miui.videoplayer com.miui.touchassistant \
    com.miui.yellowpage com.xiaomi.barrage com.xiaomi.glgm com.tencent.soter.soterserver \
    org.ifaa.aidl.manager com.miui.backup com.miui.cloudbackup com.miui.cloudservice \
    com.miui.micloudsync com.xiaomi.micloud.sdk com.xiaomi.simactivate.service \
    com.facebook.system com.facebook.appmanager com.facebook.services \
    com.microsoft.appmanager com.microsoft.deviceintegrationservice com.microsoftsdk.crossdeviceservicebroker \
    com.xiaomi.mi_connect_service com.milink.service com.xiaomi.continuity.sdkapp \
    com.xiaomi.mirror com.miui.autoui.ext com.miui.mishare.connectivity \
    com.xiaomi.aiservice com.xiaomi.aiasst.vision com.xiaomi.aon com.xiaomi.aicr \
    com.android.bips com.android.printspooler com.google.android.printservice.recommendation \
    com.android.dreams.basic com.android.dreams.phototable com.android.egg \
    com.android.bookmarkprovider com.android.providers.partnerbookmarks \
    com.google.android.marvin.talkback com.google.android.accessibility.switchaccess \
    com.google.android.adservices.api com.google.mainline.adservices com.google.mainline.telemetry \
    com.google.android.feedback com.google.android.gms.location.history com.google.android.partnersetup \
    com.google.android.apps.restore com.google.android.apps.wellbeing com.google.android.apps.safetyhub \
    com.google.ambient.streaming com.android.hotwordenrollment.okgoogle com.android.hotwordenrollment.xgoogle \
    com.android.chrome com.google.android.youtube com.google.android.apps.youtube.music \
    com.google.android.apps.photos com.google.android.gm com.google.android.apps.maps \
    com.google.android.apps.docs com.google.android.apps.subscriptions.red \
    com.google.android.apps.tachyon com.google.android.videos com.google.android.projection.gearhead

  if [ "$DO_REMOVE_GETAPPS" = "1" ]; then
    echo "=== 3B. ELIMINANDO GETAPPS (CONFIRMACION EXPLICITA) ==="
    run_sys "GETAPPS" com.xiaomi.mipicks
  else
    echo "=== 3B. GETAPPS (com.xiaomi.mipicks) CONSERVADO PARA ACTUALIZAR APPS DEL SISTEMA ==="
  fi

  if [ "$DO_EXTRA_HOS4" = "1" ]; then
    echo "=== 4. PAQUETES ESPECIFICOS DE HYPEROS 4 EEA / ANDROID 17 (7 sistema) ==="
    run_sys "HOS4_EEA_EXTRA" \
      com.google.android.federatedcompute com.google.android.ondevicepersonalization.services \
      com.google.android.aicore com.google.android.apps.setupwizard.searchselector \
      com.mediatek.ygps com.xiaomi.cameratools com.google.android.calendar
  fi

  echo "=== 5. DESHABILITANDO 2 SERVICIOS MTK DE VOZ ==="
  for p in com.mediatek.voicecommand com.mediatek.voiceunlock; do
    pm disable-user --user 0 "$p" 2>&1
  done

  echo "=== 6. AJUSTES PERSISTENTES DE SISTEMA Y 5G (KERNEL Y RAM/ZRAM 100% STOCK) ==="
  setprop persist.traced.enable 0
  stop traced 2>/dev/null || true
  stop traced_probes 2>/dev/null || true
  settings put system power_center_5g_save_mode 0
fi

if [ "$DO_ART" = "1" ]; then
  echo "=== 7. COMPILANDO AOT (speed) APPS CLAVE DE INTERFAZ Y MODULOS PRESENTES ==="
  ok=0; fail=0; skip=0
  for pkg in \
    com.mi.android.globallauncher com.miui.home miui.systemui.plugin \
    com.android.systemui com.android.settings com.miui.securitycenter \
    com.miui.securityadd com.google.android.packageinstaller com.miui.gallery \
    com.hyper.gallery.plugin com.android.camera com.android.contacts \
    com.android.incallui com.android.mms com.google.android.dialer \
    com.google.android.apps.messaging com.google.android.contacts \
    com.miui.miwallpaper com.mi.android.globalFileexplorer \
    com.google.android.inputmethod.latin com.xiaomi.calendar eu.xiaomi.ext \
    com.miui.home.kashi.ext
  do
    if ! pm path "$pkg" >/dev/null 2>&1; then skip=$((skip+1)); continue; fi
    res=$(cmd package compile -m speed -f "$pkg" 2>&1)
    if echo "$res" | grep -q "Success"; then ok=$((ok+1)); else fail=$((fail+1)); echo "  AOT FAIL: $pkg"; fi
  done
  echo "AOT_CORE_OK=$ok AOT_CORE_FAIL=$fail AOT_CORE_SKIP=$skip"
fi

if [ "$DO_USER_ART" = "1" ]; then
  echo "=== 8. COMPILANDO AOT (speed) TODAS LAS APPS DE USUARIO (-3) ==="
  uok=0; ufail=0
  for pkg in $(pm list packages -3 | sed "s/package://" | sort); do
    res=$(cmd package compile -m speed -f "$pkg" 2>&1)
    if echo "$res" | grep -q "Success"; then uok=$((uok+1)); else ufail=$((ufail+1)); echo "  USER_AOT FAIL: $pkg"; fi
  done
  echo "AOT_USER_OK=$uok AOT_USER_FAIL=$ufail"
fi
'@

$remoteScript = $header + $body + "`n'`n"
$remoteScript -replace "`r", "" | & adb @adbArgs shell sh
if ($LASTEXITCODE -ne 0) {
    Write-Host "El script termino con errores (codigo $LASTEXITCODE). Revisa la salida anterior." -ForegroundColor Red
    exit $LASTEXITCODE
}

if ($OnlyFixRustLauncherPoco) {
    Write-Host "Listo. Reinicia el telefono para que HyperOS 4 Rust Launcher Mod (com.miui.home) cargue en POCO." -ForegroundColor Green
    Write-Host "Para volver a POCO Launcher en cualquier momento, desactiva o elimina hyperos_rust_launcher_mod en KernelSU Next y reinicia." -ForegroundColor Gray
} elseif ($OnlyArtCompile) {
    Write-Host "Listo. Compilacion ART speed completada (no se modificaron ni desinstalaron apps; no requiere reinicio)." -ForegroundColor Green
} else {
    Write-Host "Listo. Reinicia el equipo para aplicar por completo la limpieza y los ajustes." -ForegroundColor Green
}
