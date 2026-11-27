> 🌐 **Español** | [English](README.en.md)

# Guía Completa de Configuración, Limpieza, Módulos y Auditoría — HyperOS 4 EEA (`OS4.0.1.0.XOJEUXM`, Android 17) + Kernel EVONIX 4.6.1 en POCO X7 Pro (`rodin_eea`)

**Detalles del dispositivo y entorno donde ha sido testeada esta guía**

| Campo | Entorno de pruebas verificado |
|---|---|
| **Dispositivo / Código** | POCO X7 Pro EEA (`rodin_eea` · `2412DPC0AG`) |
| **ROM Base** | **HyperOS 4 EEA — `OS4.0.1.0.XOJEUXM`** (Android 17 · SDK 37 · Parche `2026-11-01`) |
| **Kernel / Seguridad** | **[`6.6.144-EVONIX-HOS-V4.6.1`](https://github.com/NEESCHAL-3/EVONIX-Kernel/)** (NEESCHAL-3 · variante `HyperOS -- KSU + SUSFS`) · **SELinux `Enforcing`** · `verifiedboot = green` · `flash_locked = 1` *(con ocultación activa; sin ocultación en bootloader desbloqueado Android reporta `orange` / `0`)* · UFS `adios` · TCP `bbr` · CPU `schedutil` |
| **Root / Módulos KSU** | **[KernelSU Next](https://github.com/KernelSU-Next/KernelSU-Next)** (`com.rifsxd.ksunext`, `v3.4.2`, `u:r:ksu:s0`) · **`10` módulos activos** (`Hybrid Mount`, `Zygisk Next`, `SUSFS`, `HMA-OSS`, `Xiaomi Dialer/InCallUI/Messages`, `DisableApkVerification`, `HyperOS 4 Launcher Mod`, `Modded Security Center`, `NewUI Package Installer V3`, `FreeStyle Control Centre Mod`) *(todos opcionales)* |
| **Red / 5G y Telefonía** | `ro.vendor.radio.5g = 3` (5G NSA+SA) · `preferred_network_mode = 33,33` · `power_center_5g_save_mode = 0` · **Teléfono, InCallUI y Mensajes nativos de Xiaomi activos** mediante módulo KSU en `/system_ext/priv-app/` con `CallRecorderService` |
| **Resultados verificados en vivo** | **`130` paquetes retirados en total** (`126` por limpieza: `30` `/cust` y `/product/data-app/` + `96` sistema incluido GetApps opcional; más `4` de telefonía Google/overlay sustituidos por el módulo KSU de Dialer Xiaomi) + **`2` servicios MTK de voz deshabilitados**, **`0` resucitados**, **`0` errores `privapp`**, `traced` detenido, **`HOME = com.miui.home`**, **ART `speed` verificado (`16/16` core + `38/38` apps de usuario con DEX)**, **`7.64 GB` RAM disponibles**, **`11.13 GB` ZRAM libre (`3.27×`)**, **`120.00 Hz`**, **`0` crashes**, **`0` tombstones**, **`0` ANRs**, **`0` OOM/panics** y **`0` wakelocks activos**. |

---

## 0. Orden exacto de instalación y configuración (paso a paso)

Sigue este orden exacto desde una instalación limpia de **HyperOS 4 EEA (`OS4.0.1.0.XOJEUXM`)** para reproducir el entorno sin errores ni conflictos:

> **Requisitos en PC:** Windows con **PowerShell** y **`ADB` / `Fastboot`** ([Android Platform-Tools](https://developer.android.com/tools/releases/platform-tools)) disponible en el `PATH`. Para instalarlo y agregarlo automáticamente al `PATH` desde PowerShell, ejecuta:
> ```powershell
> winget install Google.PlatformTools
> ```
> *(Cierra y vuelve a abrir PowerShell al terminar para que el nuevo `PATH` surta efecto. Los scripts verifican automáticamente la conexión ADB y el permiso root de `Shell` antes de aplicar cambios.)*

1. **Instalar HyperOS 4 EEA (`OS4.0.1.0.XOJEUXM`) limpia y completar el primer arranque:**
   * Desde `OS3.0.303.0.WOJEUXM` stock vía actualizador oficial (Mi Pilot / OTA pública) o flasheando la Fastboot ROM oficial `.tgz` con Mi Flash Tool en modo **`clean all`** *(**NUNCA** `clean all and lock`)*.
   * Una vez iniciado en `OS4.0.1.0.XOJEUXM`, realiza **Restablecer de fábrica** desde *Ajustes → Acerca del teléfono → Restaurar de fábrica* (con el recovery stock de Android 17) y completa el asistente inicial hasta llegar al escritorio.
2. **Flashear el [Kernel EVONIX 4.6.1](https://github.com/NEESCHAL-3/EVONIX-Kernel/) (`HyperOS -- KSU + SUSFS`):**
   * Compatible oficialmente con **HyperOS 4 / Android 17** manteniendo la base Linux `6.6.144` Android GKI (`adios`, `bbr`, `schedutil`, KernelSU Next `v3.4.2` y SUSFS `v2.4.0`).
   * Si usas el paquete AnyKernel3 `.zip`, entra a **Fastboot** y flashea el **[OrangeFox específico para HyperOS 4 (Telegram)](https://t.me/PocoX7ProNepalChat/93841)** en `vendor_boot` *(build para HyperOS 4 publicado por [NEESCHAL-3](https://github.com/NEESCHAL-3) en Telegram; repositorio fuente y otros releases en [GitHub — OrangeFox-rodin-source](https://github.com/NEESCHAL-3/OrangeFox-rodin-source/))* en dos comandos separados:
     1. `fastboot flash vendor_boot <ofox_hos4>.img`
     2. `fastboot reboot` — **ni bien ejecutes este comando, mantén presionada la tecla Volumen Arriba (`Vol +`)** hasta que aparezca el logo de OrangeFox.
   * Una vez en OrangeFox, instala el `.zip` de EVONIX 4.6.1 *(sin Format Data ni wipes)* y reinicia al sistema.
3. **Instalar el gestor [KernelSU Next](https://github.com/KernelSU-Next/KernelSU-Next) (`v3.4.2`):**
   * Instala el APK (`com.rifsxd.ksunext`), ábrelo y confirma que detecta el kernel EVONIX 4.6.1 correctamente.
4. **Activar la depuración ADB en el teléfono:**
   * Ir a *Ajustes → Acerca del teléfono* (tocar 7 veces en *Versión de OS*) → *Ajustes adicionales → Opciones de desarrollador* y activar **Depuración USB** y **Depuración USB (Ajustes de seguridad)**.
5. **Habilitar acceso root para `Shell` (ADB) en KernelSU Next:**
   * Abrir **KernelSU Next → Superusuario**, buscar **`Shell`** (`com.android.shell`, UID `2000`) y activar su permiso de superusuario *(sin esto, los scripts vía `adb shell su -c ...` no podrán ejecutarse)*.
6. **Ejecutar la limpieza profunda inicial (sin compilar ART todavía) y reiniciar:**
   * Abre **[Iniciar_Menu.bat](Iniciar_Menu.bat)** y elige la **opción `1`** *(o ejecuta `.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -SkipArtCompile`)* **antes** de instalar tus apps personales.
   * Esto limpia `125` paquetes (`30` en `/cust` y `/product/data-app/` + `88` sistema base + `7` específicos HOS 4 EEA; el menú te preguntará aparte con confirmación si deseas conservar o eliminar **GetApps** `com.xiaomi.mipicks` según si lo usas primero para actualizar apps del sistema como `XMSF`), deshabilita los `2` servicios MTK de voz y aplica `traced = 0` + `power_center_5g_save_mode = 0` *(sin tocar kernel, multitarea ni las apps de telefonía de Google)*. **Reinicia el equipo** al finalizar.
7. ***(Opcional)* Configurar KernelSU Next e instalar los módulos y mods que desees (módulos base, telefonía nativa Xiaomi y/o mods de interfaz):**
   * Sigue el procedimiento completo paso a paso en la **[sección `2`](#2-stack-de-10-módulos-kernelsu-next-verificados-en-hyperos-4-eea-opcional)** *(y su guía de instalación en la **[sección `2.1`](#21-guía-rápida-para-instalar-módulos-y-mods-en-kernelsu-next-opcional)**)*. Allí tienes el orden exacto y todos los enlaces para desactivar **«Desmontar módulos por defecto»**, instalar **Hybrid Mount** *(obligatorio para cualquier módulo con carpeta `system/`)*, añadir los módulos base (`Zygisk Next`, `SUSFS`, `HMA-OSS`), instalar opcionalmente `Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA.zip` *(para tener telefonía Xiaomi retirando automáticamente la de Google)* e instalar `DisableApkVerification` junto con los mods de interfaz compatibles con Android 17 *(incluida la **opción `4`** del menú para el fix de `HyperOS 4 Launcher Mod` en POCO)*.
8. **Instalar tus apps personales y compilar ART `speed` al final:**
   * Cuando todo tu entorno definitivo esté instalado, ejecuta la **opción `5`** de **[Iniciar_Menu.bat](Iniciar_Menu.bat)** *(o `.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyArtCompile -CompileUserApps`)* para compilar todas las apps core + apps de usuario a **ART `speed`** sin volver a desinstalar nada.

---

## Estructura del repositorio

```text
POCO-X7-Pro-HyperOS4-Debloat-Optimize/
├── README.md                                             # Esta guía completa en español (paso a paso, paquetes, enlaces y auditoría)
├── README.en.md                                          # Complete guide in English
├── Iniciar_Menu.bat                                      # Doble clic en Windows: abre el menú interactivo (sin errores de ExecutionPolicy)
└── scripts/
    ├── 00_menu_hos4_eea_evonix.ps1                       # Menú interactivo visual en consola (opciones 1–9, D, R y ENTER para volver)
    ├── 01_limpieza_y_optimizacion_hos4_eea_evonix.ps1    # Limpieza (125 pkgs + GetApps opcional) + Fix Launcher POCO + ajustes + ART speed
    └── 02_revertir_optimizaciones_hos4_eea.ps1           # Revierte los ajustes de sistema y 5G (sección 3) a valores stock
```

> [!NOTE]
> Este repositorio incluye únicamente la guía y los scripts. Los binarios de terceros (kernel, gestor root y módulos) se descargan directamente desde sus enlaces oficiales indicados en la sección `0` y la sección `2`.

---

## 1. Limpieza profunda de apps (`125` base + `1` GetApps opcional = hasta `126` eliminadas por script + `2` deshabilitadas)

**Forma recomendada (menú interactivo):** haz doble clic en **[Iniciar_Menu.bat](Iniciar_Menu.bat)** *(o ejecuta `.\scripts\00_menu_hos4_eea_evonix.ps1` en PowerShell)*. Muestra el estado en vivo de ADB y Root, ordena las opciones siguiendo el flujo paso a paso, pide confirmación en operaciones destructivas *(incluida una pregunta dedicada para conservar o eliminar **GetApps**)* y vuelve automáticamente al menú principal al presionar `ENTER`.

Script CLI subyacente: **[01_limpieza_y_optimizacion_hos4_eea_evonix.ps1](scripts/01_limpieza_y_optimizacion_hos4_eea_evonix.ps1)**

> [!WARNING]
> **Lee antes de ejecutar la limpieza completa (opción `1`/`2`/`3` o script `01`):**
> * Ejecuta la limpieza completa **solo sobre una instalación limpia (antes de restaurar tus apps personales)**. Si ya instalaste apps como Facebook, TikTok, Spotify, Netflix, LinkedIn, WPS Office, Booking o Temu, el script las desinstalará salvo que las quites de la lista o uses la opción `5` (`-OnlyArtCompile`).
> * El script elimina **Google Chrome** y **Mi Browser** (quedarás sin navegador web hasta instalar el que prefieras desde Play Store), además de Gmail, Maps, YouTube, Google Fotos, Google News y Google Calendar *(se conserva **Calendario nativo de Xiaomi** `com.xiaomi.calendar`)*.
> * **GetApps (`com.xiaomi.mipicks`):** **se conserva por defecto** por si lo necesitas para actualizar tus apps del sistema; solo se elimina con confirmación explícita en el menú o pasando `-RemoveGetApps` por CLI.
> * **Telefonía de Google intacta en el script:** este script **NO elimina** Teléfono, Mensajes ni Contactos de Google porque los nativos de Xiaomi no vienen en la ROM EEA. Si quieres las apps de telefonía nativas de Xiaomi, instala el módulo opcional `Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA.zip` (`v1.1-HOS4`, paso `7` / sección `2`), el cual **elimina automáticamente las de Google** al iniciar tras confirmar el montaje de las 3 apps Xiaomi.
> * **Kernel y multitarea intactos:** este script **no modifica** parámetros del kernel EVONIX ni de RAM/ZRAM/LMKD/multitarea.

```powershell
# Forma más fácil — abrir el menú interactivo visual (o doble clic en Iniciar_Menu.bat):
.\scripts\00_menu_hos4_eea_evonix.ps1

# Uso directo por línea de comandos (avanzado, en orden cronológico):
# 1. Paso 6 — Limpieza inicial (125 apps + ajustes, conserva GetApps) SIN compilar ART todavía:
.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -SkipArtCompile

# 1B. Igual que arriba, eliminando también GetApps (com.xiaomi.mipicks):
.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -SkipArtCompile -RemoveGetApps

# 2. Paso 7 / Sección 2.1 (opcional, solo si instalaste HyperOS 4 Rust Launcher Mod en un POCO):
.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyFixRustLauncherPoco

# 3. Paso 8 (al final, tras instalar todos tus módulos y apps personales — NO desinstala nada):
.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyArtCompile -CompileUserApps

# Otros parámetros opcionales disponibles (combinables entre sí):
#   -RemoveGetApps            Elimina también GetApps (com.xiaomi.mipicks); por defecto se conserva
#   -SkipExtraHos4            Omite los 7 paquetes adicionales de HOS4 EEA (conserva AICore, Google Calendar, etc.)
#   -SkipArtCompile           Omite la compilación ART speed de las apps core de sistema/interfaz
#   -CompileUserApps          Compila también a ART speed todas las apps de usuario instaladas (-3)
#   -OnlyArtCompile           Omite limpieza y ajustes; ejecuta únicamente la compilación ART speed
#   -OnlyFixRustLauncherPoco  Parchea hyperos_rust_launcher_mod para POCO (system.prop + whiteout MiLauncherGlobal + FINDER_ACCESS)
#   -Serial <id>              Especifica el dispositivo ADB si tienes más de uno conectado
```

### 1.1. Revocaciones previas y bloqueo de OTA (`3` ajustes)

| Comando / Ajuste aplicado | Valor | Qué hace y por qué se aplica |
|---|---|---|
| `settings put secure privacy_status_com.miui.msa.global 0` | `0` | Revoca la autorización de **MIUI System Ads (MSA)** antes de desinstalarlo, evitando que el sistema intente solicitar anuncios o registrar consentimiento activo. |
| `settings put secure miui_updater_enable 0` | `0` | Desactiva las comprobaciones automáticas del actualizador OTA de Xiaomi. |
| `settings put global ota_disable_automatic_update 1` | `1` | Bloquea descargas/actualizaciones automáticas OTA en segundo plano (clave en teléfonos con root/kernel personalizado). |

*(Nota: a diferencia de HyperOS 3 Global, `com.miui.daemon` y `com.mediatek.duraspeed` ya no vienen preinstalados en HyperOS 4 EEA `OS4.0.1.0.XOJEUXM`.)*

---

### 1.2. Apps preinstaladas en `/cust` y `/product/data-app/` eliminadas (`30`)

*(Se eliminan en la limpieza inicial para partir de cero; las comerciales se reinstalan limpias desde Play Store y las de `/product/data-app/` se pueden restaurar sin flashear ROM siguiendo la sección `5.1`.)*

#### Juegos preinstalados (`9`)
| Nombre de la app | Nombre de paquete | Motivo |
|---|---|---|
| Block Juggle | `com.block.juggle` | Juego promocional preinstalado |
| Block Puzzle | `com.block.puzzle.game.hippo.mi` | Juego promocional preinstalado |
| Jewels Blast | `com.jewelsblast.ivygames.Adventure.free` | Juego promocional preinstalado |
| Eliminate Intruder 3D | `com.logame.eliminateintruder3d` | Juego promocional preinstalado |
| Tile Fun (Triple Crush) | `com.mintgames.triplecrush.tile.fun` | Juego promocional preinstalado |
| Word Trip | `com.mintgames.wordtrip` | Juego promocional preinstalado |
| Snake (NF) | `com.nf.snake` | Juego promocional preinstalado |
| Wood Blast | `com.ordinaryjoy.woodblast` | Juego promocional preinstalado |
| Bubble Shooter | `com.sukhavati.gotoplaying.bubble.BubbleShooter.mint` | Juego promocional preinstalado |

#### Apps comerciales preinstaladas (`9`)
| Nombre de la app | Nombre de paquete | Motivo |
|---|---|---|
| WPS Office | `cn.wps.moffice_eng` | Suite ofimática promocional preinstalada |
| WPS Office Lite (Xiaomi) | `cn.wps.xiaomi.abroad.lite` | Versión ligera promocional de WPS |
| Booking.com | `com.booking` | App comercial preinstalada |
| Temu | `com.einnovation.temu` | Tienda promocional preinstalada |
| LinkedIn | `com.linkedin.android` | App comercial preinstalada |
| Netflix | `com.netflix.mediaclient` | App comercial preinstalada |
| Spotify | `com.spotify.music` | App comercial preinstalada |
| Facebook | `com.facebook.katana` | Preinstalada de fábrica *(reinstalable limpia si la usas)* |
| TikTok | `com.zhiliaoapp.musically` | Preinstalada de fábrica *(reinstalable limpia si la usas)* |

#### Bloatware y utilidades en `/product/data-app/` (`12`)
| Nombre de la app | Nombre de paquete | Qué hace |
|---|---|---|
| POCO Community | `com.mi.global.pocobbs` | Foro/comunidad de POCO |
| Mi Store | `com.mi.global.shop` | Tienda online oficial de Xiaomi |
| Carrusel de fondos OS4 (Wallpaper Carousel) | `com.miui.android.fashiongallery` | Cambia fondos de bloqueo con noticias/anuncios (`MiGalleryLockScreenGlobalOs4`) |
| Mi Mover | `com.miui.huanji` | Migración inicial de datos entre teléfonos |
| Xiaomi Home | `com.xiaomi.smarthome` | Control de dispositivos domóticos Xiaomi |
| Mi Remote | `com.duokan.phone.remotecontroller` | Control remoto por infrarrojos |
| Brújula (Compass) | `com.miui.compass` | Utilidad de brújula |
| Notas (Mi Notes) | `com.miui.notes` | App de notas de Xiaomi |
| Clima (Weather) | `com.miui.weather2` | App del tiempo con contenido/sugerencias |
| ShareMe (Mi Drop) | `com.xiaomi.midrop` | Transferencia local de archivos Xiaomi |
| Escáner (Mi Scanner) | `com.xiaomi.scanner` | Escáner QR y documentos de Xiaomi |
| Google News *(nuevo en EEA)* | `com.google.android.apps.magazines` | Lector de noticias de Google (`GoogleNews_arm64_xxhdpi`) |

*(Se **conservan** en `/product/data-app/`: Editor de Galería `com.miui.mediaeditor`, Calculadora `com.miui.calculator`, Reloj `com.android.deskclock`, Grabador de pantalla `com.miui.screenrecorder`, Grabadora de voz `com.android.soundrecorder` y Calendario Xiaomi `com.xiaomi.calendar`.)*

---

### 1.3. Paquetes de sistema retirados por script (`95` base + `1` GetApps opcional = hasta `96`) y servicios MTK deshabilitados (`2`)

#### Anuncios, telemetría, auto-instaladores y tests de fábrica (`17`)
| Nombre de la app / servicio | Nombre de paquete | Qué hace |
|---|---|---|
| MIUI System Ads (MSA) | `com.miui.msa.global` | Motor de anuncios del sistema en apps Xiaomi *(consumía ~184 MB RAM en reposo)* |
| MIUI Analytics | `com.miui.analytics` | Recolección de analíticas y telemetría Xiaomi *(consumía ~148 MB RAM en reposo)* |
| MiSight Service | `com.miui.misightservice` | Telemetría y diagnóstico interno de sistema |
| Informe de errores (Bug Report) | `com.miui.bugreport` | Captura y envío de reportes de fallos Xiaomi |
| Servicios y comentarios (Mi Service) | `com.miui.miservice` | Feedback y soporte Xiaomi en segundo plano |
| Asistente de apps de terceros | `com.miui.thirdappassistant` | Seguimiento/promoción de apps de terceros |
| CatchLog | `com.bsp.catchlog` | Capturador de logs de depuración de hardware |
| DebugLoggerUI | `com.debug.loggerui` | Interfaz de logs de ingeniería MediaTek |
| Rastreo del sistema (Traceur) | `com.android.traceur` | Grabación de trazas AOSP para desarrolladores |
| Diagnóstico del dispositivo | `com.android.devicediagnostics` | Pruebas de diagnóstico Android |
| ConfigurationClient (Kryten) | `com.wdstechnology.android.kryten` | Aprovisionamiento remoto OMA de operadoras |
| Play Auto Installs (PAI) | `android.autoinstalls.config.Xiaomi.model` | Lista que auto-instala bloatware vía Play Store |
| LocationEM2 | `com.mediatek.lbs.em2.ui` | Menú de pruebas de GPS de ingeniería MediaTek |
| MDMConfig | `com.mediatek.mdmconfig` | Diagnóstico de módem MediaTek |
| MDMLSample | `com.mediatek.mdmlsample` | Cliente de prueba de logs de módem MediaTek |
| ATMWifiMeta | `com.mediatek.atmwifimeta` | Test de fábrica Wi-Fi MediaTek |
| JVFactoryTest (Fingerprint) | `com.jiiov.fingerprint_factorytest` | Test de fábrica del sensor de huellas |

#### Bloatware, tiendas, nube y OTA de Xiaomi (`22` + `1` GetApps opcional por confirmación)
| Nombre de la app / servicio | Nombre de paquete | Qué hace |
|---|---|---|
| GetApps (Mi Picks) *(opcional)* | `com.xiaomi.mipicks` | Tienda oficial de Xiaomi *(**se conserva por defecto** por si la usas para actualizar apps del sistema; solo se elimina tras confirmación en el menú o con `-RemoveGetApps`)* |
| Actualizador del sistema (OTA) | `com.android.updater` | Buscador/descargador de actualizaciones OTA |
| Actualizador de apps de sistema | `com.xiaomi.discover` | Actualiza apps Xiaomi fuera de Play Store |
| App Finder / Búsqueda | `com.mi.appfinder` | Buscador global con sugerencias online |
| App Vault (Bóveda de apps) | `com.mi.globalminusscreen` | Pantalla izquierda del launcher con tarjetas/noticias |
| Mi Browser | `com.mi.globalbrowser` | Navegador web de Xiaomi con feed de noticias |
| Mi Fitness / Health Global | `com.mi.healthglobal` | Salud y seguimiento deportivo Xiaomi |
| Limpiador (Cleaner) | `com.miui.cleaner` | Limpiador de Xiaomi con motor CleanMaster/anuncios |
| Frases frecuentes | `com.miui.phrase` | Atajos de texto frecuentes MIUI |
| Mi Music | `com.miui.player` | Reproductor de música con streaming/anuncios |
| Mi Video | `com.miui.videoplayer` | Reproductor de video con feed online/anuncios |
| Bola flotante (Quick Ball) | `com.miui.touchassistant` | Menú circular flotante de accesos rápidos |
| Páginas Amarillas (Yellow Page) | `com.miui.yellowpage` | Directorio/identificador comercial MIUI |
| Notificaciones flotantes (Barrage) | `com.xiaomi.barrage` | Mensajes deslizantes sobre juegos |
| Game Center | `com.xiaomi.glgm` | Tienda/portal de juegos Xiaomi *(no es Game Turbo)* |
| Tencent Soter Service | `com.tencent.soter.soterserver` | Autenticación biométrica para pagos chinos (WeChat) |
| IFAA Service | `org.ifaa.aidl.manager` | Autenticación biométrica para pagos chinos (Alipay) |
| Copia de seguridad MIUI | `com.miui.backup` | Respaldo local propietario de Xiaomi |
| Xiaomi Cloud Backup | `com.miui.cloudbackup` | Copias automáticas en Xiaomi Cloud |
| Xiaomi Cloud | `com.miui.cloudservice` | Servicio principal de nube Xiaomi |
| Sincronización Mi Cloud | `com.miui.micloudsync` | Sincronización en segundo plano con Mi Cloud |
| Mi Cloud SDK | `com.xiaomi.micloud.sdk` | Librería cliente de Xiaomi Cloud |
| Servicio de activación SIM Xiaomi | `com.xiaomi.simactivate.service` | Envía SMS internacionales para activar SIM en Mi Cloud |

#### Servicios de Meta y Microsoft en sistema (`6`)
| Nombre de la app / servicio | Nombre de paquete | Qué hace |
|---|---|---|
| Meta App Installer | `com.facebook.system` | Instalador silencioso en segundo plano de apps Meta |
| Meta App Manager | `com.facebook.appmanager` | Actualizador en segundo plano fuera de Play Store |
| Meta Services | `com.facebook.services` | Servicios auxiliares persistentes de Meta |
| Enlace a Windows (AppManager) | `com.microsoft.appmanager` | Integración con PC Windows |
| Device Integration Service | `com.microsoft.deviceintegrationservice` | Servicio de vinculación con Windows |
| Cross-Device Service Broker | `com.microsoftsdk.crossdeviceservicebroker` | Puente multidispositivo Microsoft |

#### Interconectividad / Cross-Device Xiaomi (`6`)
| Nombre de la app / servicio | Nombre de paquete | Qué hace |
|---|---|---|
| Mi Connect Service | `com.xiaomi.mi_connect_service` | Descubrimiento y conexión con tablets/PC Xiaomi |
| MiLink Service | `com.milink.service` | Proyección inalámbrica y transferencia MiLink |
| Interconectividad (Lyra SDK) | `com.xiaomi.continuity.sdkapp` | Continuidad de apps entre dispositivos Xiaomi |
| Xiaomi Mirror / Proyección | `com.xiaomi.mirror` | Duplicación de pantalla hacia PC/tablet Xiaomi |
| AutoUI Extension | `com.miui.autoui.ext` | Adaptación de ventanas en modo tablet/proyección |
| Mi Share | `com.miui.mishare.connectivity` | Envío rápido Wi-Fi Direct entre Xiaomi/Oppo/Vivo |

#### HyperAI prescindible (`4`)
| Nombre de la app / servicio | Nombre de paquete | Qué hace |
|---|---|---|
| HyperAI Service | `com.xiaomi.aiservice` | Servicio de asistencia IA en segundo plano |
| AI Vision | `com.xiaomi.aiasst.vision` | Reconocimiento visual IA de Xiaomi |
| Mi AON Service | `com.xiaomi.aon` | Detección continua de mirada/presencia con cámara frontal |
| MIUI AICR | `com.xiaomi.aicr` | Motor IA local de detección de capas *(consumía ~181 MB RAM en reposo; si editas un fondo por capas y se queda en «Detectando capas», se restaura con `cmd package install-existing com.xiaomi.aicr`)* |

#### AOSP, impresión y accesibilidad no usada (`10`)
| Nombre de la app / servicio | Nombre de paquete | Qué hace |
|---|---|---|
| Servicio de impresión predeterminado | `com.android.bips` | Impresión Wi-Fi integrada AOSP |
| Cola de impresión (Print Spooler) | `com.android.printspooler` | Gestor de trabajos de impresión |
| Recomendación de impresión Google | `com.google.android.printservice.recommendation` | Sugerencias de plugins de impresoras |
| Salvapantallas básicos | `com.android.dreams.basic` | Protectores de pantalla al cargar |
| Salvapantallas de fotos | `com.android.dreams.phototable` | Collage de fotos en reposo |
| Android Easter Egg | `com.android.egg` | Minijuego oculto de versión Android |
| Proveedor de marcadores | `com.android.bookmarkprovider` | Marcadores legacy AOSP |
| Marcadores de socios | `com.android.providers.partnerbookmarks` | Marcadores predefinidos por fabricante/operador |
| TalkBack | `com.google.android.marvin.talkback` | Lector de pantalla por voz para accesibilidad |
| Accesibilidad con interruptores | `com.google.android.accessibility.switchaccess` | Control del teléfono mediante interruptores externos |

#### Telemetría y apps opcionales de Google (`23`)
| Nombre de la app / servicio | Nombre de paquete | Qué hace |
|---|---|---|
| AdServices API | `com.google.android.adservices.api` | Privacy Sandbox / segmentación publicitaria |
| Mainline AdServices | `com.google.mainline.adservices` | Módulo Mainline de anuncios Android |
| Mainline Telemetry | `com.google.mainline.telemetry` | Telemetría de módulos Mainline |
| Comentarios de Google (Feedback) | `com.google.android.feedback` | Envío de informes de error a Google |
| Historial de ubicaciones | `com.google.android.gms.location.history` | Registro continuo de ubicaciones Google |
| Google Partner Setup | `com.google.android.partnersetup` | Configuración inicial de socios/OEM |
| Restauración de datos Google | `com.google.android.apps.restore` | Migración inicial desde otro Android/iPhone |
| Bienestar digital | `com.google.android.apps.wellbeing` | Contador de tiempo en pantalla en segundo plano |
| Seguridad personal | `com.google.android.apps.safetyhub` | Detección de accidentes y emergencias Google |
| Cross-Device Services | `com.google.ambient.streaming` | Transmisión de apps entre dispositivos Google |
| OK Google Enrollment | `com.android.hotwordenrollment.okgoogle` | Entrenamiento de escucha continua «OK Google» |
| Hey Google Enrollment | `com.android.hotwordenrollment.xgoogle` | Entrenamiento de escucha continua «Hey Google» |
| Google Chrome | `com.android.chrome` | Navegador Chrome *(WebView `150.0.7871.181` permanece intacto)* |
| YouTube | `com.google.android.youtube` | App oficial *(opcional; reinstalable desde Play Store)* |
| YouTube Music | `com.google.android.apps.youtube.music` | App oficial *(opcional; reinstalable desde Play Store)* |
| Google Fotos | `com.google.android.apps.photos` | Nube/galería Google *(se conserva Galería nativa de Xiaomi)* |
| Gmail | `com.google.android.gm` | Cliente de correo Google |
| Google Maps | `com.google.android.apps.maps` | Mapas Google |
| Google Drive | `com.google.android.apps.docs` | Almacenamiento Drive |
| Google One | `com.google.android.apps.subscriptions.red` | Suscripciones y copias Google One |
| Google Meet | `com.google.android.apps.tachyon` | Videollamadas Google |
| Google TV | `com.google.android.videos` | Alquiler/streaming Google TV |
| Android Auto | `com.google.android.projection.gearhead` | Proyección en pantallas de automóvil |

#### Específicos de HyperOS 4 EEA / Android 17 (`7` — *omitibles con `-SkipExtraHos4`*)
| Nombre de la app / servicio | Nombre de paquete | Qué hace |
|---|---|---|
| Federated Compute | `com.google.android.federatedcompute` | Entrenamiento ML federado de Google en segundo plano |
| On-Device Personalization | `com.google.android.ondevicepersonalization.services` | Servicios Privacy Sandbox / personalización local de Android 17 |
| Android AICore | `com.google.android.aicore` | Stub OEM de Gemini Nano local *(evita descargas de modelos locales de varios GB; Gemini nube `com.google.android.apps.bard` sigue funcionando)* |
| Search Selector (EEA DMA) | `com.google.android.apps.setupwizard.searchselector` | Selector europeo de buscador/navegador solo usado en el asistente inicial |
| YGPS MediaTek | `com.mediatek.ygps` | Herramienta de pruebas de satélites GPS de ingeniería MediaTek |
| CameraTools Beta | `com.xiaomi.cameratools` | Volcador de logs de depuración de cámara (`DumpLogProvider`; **no** afecta la Cámara nativa) |
| Google Calendar | `com.google.android.calendar` | App duplicada *(se conserva **Calendario Xiaomi** `com.xiaomi.calendar` y el proveedor base del sistema)* |

#### Reemplazo opcional de Google Teléfono / Mensajes / Contactos (automático al instalar el módulo KSU de telefonía Xiaomi)
*(**NO forma parte del script de limpieza.** Si deseas tener las apps de telefonía nativas de Xiaomi en HyperOS 4 EEA, instala el módulo `Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA.zip` `v1.1-HOS4` — paso `7` / sección `2`: tras verificar al reiniciar que las 3 apps de Xiaomi cargaron bien, el propio módulo elimina automáticamente los `4` paquetes de Google/overlay, asigna los roles `DIALER`/`SMS` y los restaura automáticamente si lo desinstalas.)*

| Acción | Nombre de la app | Nombre de paquete | Rol / Función |
|---|---|---|---|
| **Retirado** | Teléfono de Google | `com.google.android.dialer` | Sustituido por marcador nativo Xiaomi |
| **Retirado** | Mensajes de Google | `com.google.android.apps.messaging` | Sustituido por Mensajes nativo Xiaomi |
| **Retirado** | Contactos de Google | `com.google.android.contacts` | Sustituido por Contactos nativo Xiaomi |
| **Retirado** | Overlay Teléfono Google MIUI | `com.android.phone.cust.overlay.miui` | Overlay que forzaba dialer de Google |
| **Activo (módulo KSU)** | Teléfono y Contactos Xiaomi | `com.android.contacts` | Rol **`DIALER`** predeterminado (`18.30.00.75`) |
| **Activo (módulo KSU)** | Interfaz de llamadas Xiaomi | `com.android.incallui` | Pantalla de llamada + grabadora (`40.01.63`, `targetSdk 37`) |
| **Activo (módulo KSU)** | Mensajes Xiaomi Global | `com.android.mms` | Rol **`SMS`** predeterminado (`18.0.0.54-gl`) |
| **Activo (ROM)** | Grabadora de llamadas MTK | `com.mediatek.callrecorder` | Servicio `CallRecorderService` presente |

#### Servicios MediaTek de voz deshabilitados (`pm disable-user --user 0`, `2`)
| Nombre del servicio | Nombre de paquete | Qué hace y por qué se deshabilita |
|---|---|---|
| MTK Voice Command | `com.mediatek.voicecommand` | Escucha de comandos de voz por hardware MediaTek *(deshabilitado a nivel de usuario sin eliminar el paquete `UID 1000`)* |
| MTK Voice Unlock | `com.mediatek.voiceunlock` | Desbloqueo por voz MediaTek (no usado) |

---

### 1.4. Paquetes esenciales conservados (Lista Roja HyperOS 4 EEA)

| Nombre | Paquete | Por qué se conserva |
|---|---|---|
| POCO Launcher / HyperOS Launcher *(mod)* | `com.mi.android.globallauncher` / `com.miui.home` | Escritorio, gestos y Recientes (`HOME` activo) |
| Plugin de SystemUI / FreeStyle Control Centre *(mod)* | `miui.systemui.plugin` | Centro de control y ajustes rápidos |
| Interfaz del sistema | `com.android.systemui` | Barra de estado, notificaciones y pantalla de bloqueo |
| Seguridad Xiaomi / Modded Security Center *(mod)* | `com.miui.securitycenter` | Permisos, batería, Game Turbo y seguridad base |
| Complemento y Núcleo de Seguridad | `com.miui.securityadd`, `com.miui.securitycore` | Motor de Game Turbo, ventanas flotantes y servicios de seguridad |
| PowerKeeper y PowerInsight *(HOS4)* | `com.miui.powerkeeper`, `com.miui.powerinsight` | Perfiles térmicos, tasa de refresco, energía y estadísticas de batería |
| Joyose y GPU Game Driver *(MT6899)* | `com.xiaomi.joyose`, `com.mediatek.mt6989.gamedriver` | Perfiles térmicos/juegos y driver gráfico del Dimensity 8400-Ultra |
| TouchService y NovaJarvis | `com.xiaomi.touchservice`, `com.novatek.novavis` | Calibración táctil y procesamiento de pantalla |
| HyperComm, VsimCore y ModemTestBox | `com.xiaomi.hypercomm`, `com.miui.vsimcore`, `com.xiaomi.mtb` | Comunicaciones HyperOS, soporte módem/radio y paquete `UID 1000` dormido |
| MIUI Global Layout | `com.mi.globallayout` | Adaptación de diseño global de interfaz |
| Buscar dispositivo | `com.xiaomi.finddevice` | Evita bootloop en HyperOS *(nunca desinstalar)* |
| Xiaomi Push (XMSF) | `com.xiaomi.xmsf` | Framework de notificaciones push del sistema |
| Galería, Plugin HOS4 y Editor | `com.miui.gallery`, `com.hyper.gallery.plugin`, `com.miui.mediaeditor` | Visor, plugin de HyperOS 4 y editor nativo de fotos/videos |
| Cámara y CameraMind *(HOS4)* | `com.android.camera`, `com.xiaomi.cameramind` | Cámara nativa Xiaomi y motor IA de cámara *(quitar `cameramind` crashea Cámara)* |
| Administrador de archivos y Calendario | `com.mi.android.globalFileexplorer`, `com.xiaomi.calendar` | Explorador de archivos y calendario nativo Xiaomi |
| Telefonía activa y capa HyperPhone | `com.android.contacts`, `com.android.incallui`, `com.android.mms`, `com.mediatek.callrecorder`, `com.xiaomi.phone`, `com.xiaomi.incallui` | Suite nativa Xiaomi vía módulo KSU *(si no instalas el módulo KSU, conserva Teléfono/Mensajes/Contactos de Google)* |
| Android Developer Verifier *(Android 17)* | `com.google.android.verifier` | Servicio de verificación de APKs en Android 17 *(quitarlo puede romper instalaciones externas)* |
| Gboard y Gemini | `com.google.android.inputmethod.latin`, `com.google.android.apps.bard` | Teclado predeterminado y asistente en la nube |
| WebView, GMS, Play Store | `com.google.android.webview`, `com.google.android.gms`, `com.android.vending` | Motor web (`150.0.7871.181`), Play Services y tienda oficial |
| KernelSU Next | `com.rifsxd.ksunext` | Gestor root a nivel kernel |

---

## 2. Stack de 10 módulos KernelSU Next verificados en HyperOS 4 EEA (opcional)

> [!NOTE]
> La instalación de **todos estos módulos es completamente opcional** (no solo los mods de interfaz, también los módulos base de montaje, Zygisk, ocultación y Dialer). Esta lista refleja el **stack completo utilizado y verificado en vivo** sobre HyperOS 4 EEA / Android 17 (SDK 37).

| # | Módulo (`id`) | Versión | Estado verificado / Qué hace | Dónde obtenerlo |
|---:|---|---|---|---|
| 1 | **Hybrid Mount** (`hybrid_mount`) | `6.2.6` | Metamódulo de montaje (`OverlayFS` / `Magic Mount` / `VFS`) necesario en KernelSU Next v3+ (`9` montajes `OverlayFS`, `0` errores, `degraded = false`) | [GitHub — Hybrid-Mount/meta-hybrid_mount](https://github.com/Hybrid-Mount/meta-hybrid_mount) |
| 2 | **Zygisk Next** (`zygisksu`) | `1.5.3 (880)` | Inyección Zygisk standalone para KernelSU (`[✅zygote, KernelSU 33365]`, `0` errores en Android 17) | [GitHub — Dr-TSNG/ZygiskNext](https://github.com/Dr-TSNG/ZygiskNext) |
| 3 | **SUSFS-FOR-KERNELSU** (`susfs4ksu`) | `v2.4.0-R28` | Oculta rastros de root, montajes y kernel personalizado (`status: ✅ SuS`, `verifiedboot = green`, `flash_locked = 1`) | [GitHub — sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) |
| 4 | **HMA-OSS Zygisk** (`hma_oss_zygisk`) | `oss-177` | Backend Zygisk de *Hide My Applist OSS* (`[✅ System service loaded]`, junto con la app `org.frknkrc44.hma_oss`); oculta apps instaladas (root/mods) a otras apps | [GitHub — frknkrc44/HMA-OSS](https://github.com/frknkrc44/HMA-OSS/) |
| 5 | **Xiaomi Dialer, InCallUI & Messages** (`xiaomi_dialer_mms_hos4_eea`) | `v1.1-HOS4` | Instala Teléfono/Contactos (`18.30.00.75`), InCallUI (`40.01.63` + grabadora) y Mensajes (`18.0.0.54-gl`) nativos de Xiaomi en `/system_ext/priv-app/` con `65` `privapp-permissions` para Android 17 (`enforce`). **Al instalarlo y reiniciar, elimina automáticamente las apps de telefonía de Google** (`Dialer`, `Messages`, `Contacts` + overlay MIUI) y fija los roles `DIALER`/`SMS` *(y las restaura automáticamente al desinstalarlo; no requiere `DisableApkVerification`)* | [GitHub Releases — `v1.1-HOS4`](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-Debloat-Optimize/releases/tag/v1.1-HOS4) |
| 6 | **DisableApkVerification** (`DisableApkVerification`) | `v4` | Desactiva la verificación estricta de firmas APK en `framework.jar`, `services.jar` y `miui-services.jar` para permitir apps de sistema modificadas | [GitLab — mods-center/Apk-Signature-Verification-Patch](https://gitlab.com/mods-center/Apk-Signature-Verification-Patch) |
| 7 | **HyperOS 4 Launcher Mod (Rust/Flutter)** (`hyperos_rust_launcher_mod`) | `v1.4` | Reemplaza POCO Launcher por HyperOS 4 Launcher modificado (`com.miui.home` `8.01.02.9258`, dock nativo, soft glass, widgets/iconos) + `HyperLauncherExt` (`3.9`) *(en POCO requiere ejecutar la opción `4` del menú; si prefieres no aplicar el fix, usa como alternativa [HyperOS-Launcher](https://gitlab.com/mods-center/HyperOS-Launcher))* | [GitLab — mods-center/HyperOS-Rust-Launcher-Mod](https://gitlab.com/mods-center/HyperOS-Rust-Launcher-Mod) · [Telegram — Mods Center](https://t.me/kashis_cringey_stuffs) |
| 8 | **Modded Security Center** (`security_app_mod`) | `v8` | Centro de seguridad y Game Turbo modificados (`com.miui.securitycenter` `13.8.0-261020.0.1`) | [GitLab — mods-center/HyperOS-Security-Center](https://gitlab.com/mods-center/HyperOS-Security-Center) |
| 9 | **NewUI Package Installer V3** (`newui_package_installer`) | `3.0` | Instalador de paquetes con nueva interfaz (`com.google.android.packageinstaller` `17-15544436`, `targetSdk 37`) | [GitLab — mods-center/Package-Installer](https://gitlab.com/mods-center/Package-Installer) |
| 10 | **FreeStyle Control Centre Mod** (`freestyle_plugin_mod`) | `v1` | Centro de control personalizable (`miui.systemui.plugin` `18.3.2.34.0`) | [GitLab — mods-center/FreeStyle-Control-Center](https://gitlab.com/mods-center/FreeStyle-Control-Center) |

*(Requisitos puntuales: **SUSFS-FOR-KERNELSU** requiere un kernel compilado con soporte SUSFS como EVONIX; **HMA-OSS Zygisk** requiere **Zygisk Next** — módulo `#2` — y su app acompañante `org.frknkrc44.hma_oss`; los mods de interfaz `#7` a `#10` requieren **DisableApkVerification** — módulo `#6` — instalado y reiniciado previamente.)*

> [!WARNING]
> **Compatibilidad de mods de interfaz con Android 17 (SDK 37):** usa únicamente versiones actualizadas compatibles con **HyperOS 4 / Android 17** (como las versiones listadas arriba). Instalar mods antiguos compilados para HyperOS 3 puede provocar cierres de `SystemUI` o bootloop.

### 2.1. Guía rápida para instalar módulos y mods en KernelSU Next (opcional)

> [!NOTE]
> Este procedimiento aplica **únicamente para KernelSU / KernelSU Next** *(en otros gestores de root el procedimiento podría ser diferente)*.

1. **Desactivar «Desmontar módulos por defecto» (*Unmount modules by default*) *(obligatorio para montar módulos de sistema)*:**
   * Abre **KernelSU Next → pestaña Ajustes** y desactiva la opción **Desmontar módulos por defecto**.
2. **Instalar el metamódulo Hybrid Mount *(obligatorio en KernelSU Next v3+ para módulos con carpeta `system/`)*:**
   * Descarga e instala **[Hybrid Mount (`6.2.6`, Releases)](https://github.com/Hybrid-Mount/meta-hybrid_mount/releases)**, elige **OverlayFS** o **Magic Mount** *(**OverlayFS** suele tener menos errores, aunque ambos funcionan)* y **reinicia**.
3. **Instalar módulos base y *(opcional)* el módulo de telefonía nativa Xiaomi:**
   * Instala **[Zygisk Next (`1.5.3`)](https://github.com/Dr-TSNG/ZygiskNext/releases)**, **[SUSFS-FOR-KERNELSU (`v2.4.0-R28`)](https://github.com/sidex15/susfs4ksu-module/releases)** y **[HMA-OSS](https://github.com/frknkrc44/HMA-OSS/releases)** *(si los usas)*, reiniciando y verificando que arranquen sin errores.
   * *(Opcional — solo si deseas tener las apps de telefonía nativas de Xiaomi en EEA)* Descarga e instala **[Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA.zip (`v1.1-HOS4`)](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-Debloat-Optimize/releases/tag/v1.1-HOS4)** y **reinicia** *(requiere los pasos `1` y `2`, pero **no** requiere `DisableApkVerification`)*. Este módulo instala **Teléfono/Contactos**, **InCallUI (con grabadora de llamadas)** y **Mensajes** de Xiaomi en `/system_ext/priv-app/` con sus `65` permisos `privapp` para Android 17; al reiniciar, tras confirmar que las 3 apps Xiaomi cargaron bien, **elimina automáticamente las apps de telefonía de Google** (`com.google.android.dialer`, `com.google.android.apps.messaging`, `com.google.android.contacts` y `com.android.phone.cust.overlay.miui`) y asigna los roles **`DIALER = com.android.contacts`** y **`SMS = com.android.mms`** *(y si desinstalas el módulo desde KernelSU Next, las restaura automáticamente al reiniciar)*.
4. ***(Solo si vas a usar mods de interfaz de sistema compatibles con Android 17 — requiere obligatoriamente los pasos `1` y `2` anteriores: «Desmontar módulos por defecto» desactivado + Hybrid Mount instalado y reiniciado)*** **Instalar `DisableApkVerification` y tus mods de interfaz:**
   * Sin ambos requisitos previos (pasos `1` y `2`), los archivos de sistema de `DisableApkVerification` y de los mods de interfaz no se montarán.
   * Descarga e instala primero la última versión compatible con HyperOS 4 de **[DisableApkVerification (`v4`)](https://gitlab.com/mods-center/Apk-Signature-Verification-Patch)** y **reinicia**.
   * Después instala los mods de interfaz que desees de la tabla anterior (**[HyperOS 4 Launcher Mod](https://gitlab.com/mods-center/HyperOS-Rust-Launcher-Mod)**, **[Modded Security Center](https://gitlab.com/mods-center/HyperOS-Security-Center)**, **[NewUI Package Installer V3](https://gitlab.com/mods-center/Package-Installer)**, **[FreeStyle Control Centre Mod](https://gitlab.com/mods-center/FreeStyle-Control-Center)**), reiniciando tras instalar.
5. ***(Solo si instalas HyperOS 4 Rust Launcher Mod `hyperos_rust_launcher_mod` en POCO)*** **Aplicar el fix de compatibilidad POCO:**
   * En equipos `POCO`, `PackageManagerServiceImpl.initIgnoreApps()` omite `/product/priv-app/MiuiHome` siempre que exista `/product/priv-app/MiLauncherGlobal` (y ambos launchers comparten `14` `ContentProvider`, por lo que no pueden coexistir).
   * Tras instalar **[HyperOS 4 Launcher Mod (Rust/Flutter)](https://gitlab.com/mods-center/HyperOS-Rust-Launcher-Mod)** en KernelSU Next, abre **[Iniciar_Menu.bat](Iniciar_Menu.bat)** y ejecuta la **opción `4`** *(o `.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyFixRustLauncherPoco`)* y **reinicia**. Esto crea de forma no destructiva dentro del módulo: `system.prop` (`ro.miui.product.home=com.miui.home`), el whiteout `MiLauncherGlobal/.remove` para Hybrid-Mount *(o `mknod c 0 0` en OverlayFS estándar)*, agrega `com.mi.appfinder.normal.permission.FINDER_ACCESS` a `privapp-permissions-com.miui.home-mod.xml` para Android 17 (`enforce`) y limpia la caché de escaneo.
   * Si más adelante actualizas `hyperos_rust_launcher_mod` a una nueva versión que aún no incluya soporte POCO, vuelve a ejecutar la **opción `4`** antes de reiniciar. Para volver a POCO Launcher basta con desactivar o eliminar el módulo en KernelSU Next y reiniciar.
   * **Alternativa sin aplicar el fix para el Launcher Rust:** si prefieres no usar el parche para `hyperos_rust_launcher_mod`, tienes disponible como alternativa el mod tradicional de HyperOS Launcher en **[GitLab — mods-center/HyperOS-Launcher](https://gitlab.com/mods-center/HyperOS-Launcher)** *(no instales ambos launchers a la vez)*.

> [!IMPORTANT]
> **Reinicia siempre tras instalar módulos** y no mezcles módulos de interfaz sin confirmar compatibilidad con Android 17.

---

## 3. Ajustes activos y compilación ART `speed` (con explicación)

### 3.1. Ajustes persistentes aplicados (sin tocar kernel ni multitarea)

| Comando / Configuración | Valor activo | Qué hace |
|---|---|---|
| `setprop persist.traced.enable 0` + `stop traced` + `stop traced_probes` | `0` (`stopped`) | Desactiva el daemon de trazado de rendimiento **Perfetto** (`traced` y `traced_probes`), que solo sirve para perfiles de desarrolladores y consume memoria/CPU en segundo plano de forma innecesaria. |
| `settings put system power_center_5g_save_mode 0` | `0` | Desactiva el modo de ahorro agresivo de 5G de HyperOS para evitar que baje innecesariamente de 5G a 4G cuando hay cobertura. |
| `cmd package compile -m speed -f <paquete>` | `speed` | Compila por adelantado (**AOT**) todo el código DEX de la app a código nativo `arm64`. Reduce la carga de CPU, evita compilación JIT al vuelo y mejora la fluidez de aperturas y animaciones. |

### 3.2. Cobertura verificada de compilación ART `speed` (post-módulos y apps)
* **Cuándo ejecutarla:** una vez instalados tus módulos/mods definitivos y todas tus apps personales, ejecuta la **opción `5`** en **[Iniciar_Menu.bat](Iniciar_Menu.bat)** *(o `.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyArtCompile -CompileUserApps`)*. No vuelve a desinstalar nada ni requiere reinicio.
* **`16 / 16` apps core con código DEX verificadas en `arm64: [status=speed]` (`18 / 18` procesadas, `0` fallos):** `miui.systemui.plugin` (Centro de Control), `com.android.systemui` (SystemUI), `com.android.settings` (Ajustes), `com.miui.securitycenter` (Seguridad), `com.miui.securityadd` (Game Turbo), `com.google.android.packageinstaller` (Instalador), `com.hyper.gallery.plugin` (Plugin Galería HOS4), `com.android.camera` (Cámara), `com.android.contacts` (Teléfono/Contactos Xiaomi), `com.android.incallui` (Llamadas Xiaomi), `com.android.mms` (Mensajes Xiaomi), `com.miui.miwallpaper` (Fondos), `com.mi.android.globalFileexplorer` (Archivos), `com.google.android.inputmethod.latin` (Gboard), `com.xiaomi.calendar` (Calendario) y `com.miui.home.kashi.ext` (HyperLauncherExt) *(las otras `2` presentes — `com.miui.home` Rust/Flutter y `com.miui.gallery` — no tienen código DEX que compilar; el script contempla `23` candidatas y omite automáticamente las no presentes)*.
* **`38 / 38` apps de usuario con código DEX verificadas en `arm64: [status=speed]` (`40 / 40` procesadas, `0` fallos):** todas las apps personales y juegos instalados *(los `2` paquetes auxiliares de Google sin código DEX — `com.google.android.contactkeys` y `com.google.android.safetycore` — no requieren compilación OAT)*.

---

## 4. Resultados de auditoría en vivo en el dispositivo de pruebas (stack completo de 10 módulos)

* **Sistema y seguridad:** **HyperOS 4 EEA (`OS4.0.1.0.XOJEUXM`)** · Android 17 (SDK 37 · parche `2026-11-01`) · **`6.6.144-EVONIX-HOS-V4.6.1`** · **SELinux `Enforcing`** · **`verifiedboot = green`** · **`flash_locked = 1`** *(con SUSFS `v2.4.0-R28` activo)* · **`10 / 10` módulos KernelSU Next activos** (**Hybrid Mount `6.2.6`**: `9` montajes `OverlayFS`, `degraded = false`, `0` errores; **Zygisk Next `1.5.3`**, **SUSFS `v2.4.0-R28`**, **HMA-OSS `oss-177`** `[✅ System service loaded]`, **Xiaomi Dialer/InCallUI/Messages**, **DisableApkVerification `v4`**, **HyperOS 4 Launcher Mod `v1.4`**, **Modded Security Center `v8`**, **NewUI Package Installer `3.0`**, **FreeStyle Control Centre `v1`**).
* **Estabilidad profunda:** **`0` crashes** (`FATAL = 0`, `native = 0`) · **`0` errores `privapp`** (permisos privilegiados de Launcher, Dialer/InCallUI/Messages, Security Center y Package Installer concedidos con `granted=true`) · **`0` tombstones** · **`0` ANRs** · **`0` OOM / kernel panics** · **`0` wakelocks activos** (`Wake Locks: size=0`).
* **CPU, RAM, ZRAM, I/O y pantalla:**
  * **RAM (`11.03 GB` útiles):** **`7.64 GB` disponibles (`MemAvailable`)** (`2.45 GB` libres + `4.72 GB` caché).
  * **ZRAM (`12 GB [lz4]`, `extm = 0`, `swappiness = 100`, `page-cluster = 3` — 100 % stock):** **`888 MB` usados** comprimidos en **`271 MB` físicos** (ratio **`3.27×`**) · **`11.13 GB` libres**.
  * **Kernel EVONIX 4.6.1 intacto:** UFS **`[adios]`** · TCP **`bbr`** · CPU **`schedutil`** (3 clústeres).
  * **Pantalla:** `1220×2712` **activa a `120.00 Hz`** (`30 / 60 / 90 / 120 Hz`).
* **Integridad de limpieza, mods de interfaz y telefonía nativa Xiaomi:**
  * **`130 / 130` paquetes retirados (`0` resucitados)** *(`126` por limpieza incluido GetApps `com.xiaomi.mipicks` retirado opcionalmente tras actualizar `XMSF` a `6.2.67-G` + `4` de telefonía Google/overlay sustituidos por el módulo Xiaomi)* · **`2 / 2` servicios MTK de voz deshabilitados**.
  * `privacy_status_msa = 0`, `miui_updater_enable = 0`, `ota_disable_automatic_update = 1`, `traced = stopped`, `traced_probes = stopped`, `power_center_5g_save_mode = 0`, `preferred_network_mode = 33,33`.
  * **Launcher y mods activos:** **`HOME = com.miui.home`** (`RELEASE-8.01.02.9258-261013-11132207-R`, `ro.miui.product.home = com.miui.home`, `/product/priv-app/MiLauncherGlobal` oculto por whiteout, `HyperLauncherExt 3.9` activo) · **`Security Center`** (`13.8.0-261020.0.1`) · **`SystemUI Plugin`** (`18.3.2.34.0`) · **`Package Installer`** (`17-15544436`, `targetSdk 37`).
  * **Telefonía y componentes base:** **`DIALER = com.android.contacts`** (`18.30.00.75`), **`InCallUI`** (`40.01.63`), **`SMS = com.android.mms`** (`18.0.0.54-gl`), **`CallRecorderService`** (`com.mediatek.callrecorder`), `IME = Gboard`, `WebView = 150.0.7871.181`.
  * **Compilación ART `speed` completada (`0` fallos):** **`16 / 16`** apps core con DEX (`18 / 18` procesadas; `com.miui.home` Rust/Flutter y `com.miui.gallery` sin DEX) + **`38 / 38`** apps de usuario con DEX (`40 / 40` procesadas; `2` paquetes auxiliares sin DEX) verificadas en **`arm64: [status=speed]`**.

---

## 5. Cómo revertir cambios y restaurar cualquier app desinstalada

> [!TIP]
> Todas las acciones de restauración de apps (incluido un **selector numerado automático** para las apps de `/product/data-app/`), rehabilitación de servicios MediaTek, restablecimiento de ART y reversión de ajustes están integradas en las **opciones `7` y `8` de [Iniciar_Menu.bat](Iniciar_Menu.bat)** ([00_menu_hos4_eea_evonix.ps1](scripts/00_menu_hos4_eea_evonix.ps1)).

### 5.1. Restaurar cualquier app desinstalada

Según el tipo de paquete eliminado, usa el método correspondiente *(no necesitas flashear la ROM ni perder datos)*:

1. **Apps y servicios de sistema (sección `1.3`, eliminados con `pm uninstall --user 0`):**
   ```powershell
   adb shell cmd package install-existing <nombre.del.paquete>
   ```
   *Ejemplos:* `adb shell cmd package install-existing com.xiaomi.aicr` · `adb shell cmd package install-existing com.google.android.calendar`
   *(Si desinstalas el módulo `Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA.zip` `v1.1-HOS4` desde KernelSU Next, al reiniciar restaurará automáticamente `com.google.android.dialer`, `com.google.android.apps.messaging`, `com.google.android.contacts` y `com.android.phone.cust.overlay.miui`; si solo lo desactivas temporalmente, puedes restaurarlos a mano con `cmd package install-existing`.)*

2. **Apps preinstaladas en `/product/data-app/` (sección `1.2`, como Brújula, Escáner, Notas, Clima, Mi Remote, ShareMe, Google News, etc.):**
   Sus APKs originales firmados siguen guardados dentro de `/product/data-app/` en la ROM:
   ```powershell
   # 1. Listar las carpetas de APKs originales disponibles en la ROM:
   adb shell "su -c 'ls /product/data-app/'"

   # 2. Ver el nombre exacto del .apk dentro de la carpeta elegida (ejemplo: Brújula):
   adb shell "su -c 'ls /product/data-app/MIUICompassGlobal/'"

   # 3. Restaurar instalando el APK original y limpiando el archivo temporal:
   adb shell "su -c 'cp /product/data-app/MIUICompassGlobal/MIUICompassGlobal.apk /data/local/tmp/app.apk && chmod 644 /data/local/tmp/app.apk && pm install /data/local/tmp/app.apk && rm -f /data/local/tmp/app.apk'"
   ```
   *(Cambia `MIUICompassGlobal/MIUICompassGlobal.apk` por cualquier otra app disponible, por ejemplo `MiuiScanner/MiuiScanner.apk` para Escáner o `GoogleNews_arm64_xxhdpi/GoogleNews_arm64_xxhdpi.apk` para Google News).*

3. **Apps comerciales / de terceros (sección `1.2`, como Netflix, Spotify, Facebook, TikTok, etc.):**
   Se reinstalan limpias y actualizadas directamente desde **Google Play Store**.

4. **Rehabilitar los 2 servicios MediaTek de voz deshabilitados:**
   ```powershell
   adb shell "su -c 'pm enable com.mediatek.voicecommand && pm enable com.mediatek.voiceunlock'"
   ```

### 5.2. Revertir ajustes, módulos y compilación ART

* **Revertir ajustes de sistema y 5G (sección `3`: `traced` y ahorro 5G):** ejecutar **[02_revertir_optimizaciones_hos4_eea.ps1](scripts/02_revertir_optimizaciones_hos4_eea.ps1)** y reiniciar *(este script no revierte las revocaciones de privacidad ni el bloqueo OTA de la sección `1.1`)*.
* **Desactivar o quitar cualquier módulo KSU:** desde **KernelSU Next → Módulos** y reiniciar.
* **Restablecer compilación ART de una app (vuelve al perfil estándar de Android):**
  ```powershell
  adb shell "su -c 'cmd package compile --reset <nombre.del.paquete>'"
  ```

---

## Agradecimientos y créditos

* Agradecimiento especial a **[NEESCHAL-3](https://github.com/NEESCHAL-3)** por su excelente trabajo en el **[Kernel EVONIX](https://github.com/NEESCHAL-3/EVONIX-Kernel/)** y el recovery **OrangeFox para POCO X7 Pro (`rodin`)** ([repositorio en GitHub](https://github.com/NEESCHAL-3/OrangeFox-rodin-source/) · [build HyperOS 4 en Telegram](https://t.me/PocoX7ProNepalChat/93841)). Puedes ver todos sus proyectos y lanzamientos en su perfil de GitHub: **[github.com/NEESCHAL-3](https://github.com/NEESCHAL-3)**.
