> 🌐 [Español](README.md) | **English**

# Complete Setup, Debloat, Modules & Audit Guide — HyperOS 4 EEA (`OS4.0.1.0.XOJEUXM`, Android 17) + EVONIX 4.6.1 Kernel on POCO X7 Pro (`rodin_eea`)

**Device and test environment details where this guide was verified**

| Field | Verified Test Environment |
|---|---|
| **Device / Codename** | POCO X7 Pro EEA (`rodin_eea` · `2412DPC0AG`) |
| **Base ROM** | **HyperOS 4 EEA — `OS4.0.1.0.XOJEUXM`** (Android 17 · SDK 37 · Patch `2026-11-01`) |
| **Kernel / Security** | **[`6.6.144-EVONIX-HOS-V4.6.1`](https://github.com/NEESCHAL-3/EVONIX-Kernel/)** (NEESCHAL-3 · `HyperOS -- KSU + SUSFS` variant) · **SELinux `Enforcing`** · `verifiedboot = green` · `flash_locked = 1` *(with hiding active; without hiding on an unlocked bootloader Android reports `orange` / `0`)* · UFS `adios` · TCP `bbr` · CPU `schedutil` |
| **Root / KSU Modules** | **[KernelSU Next](https://github.com/KernelSU-Next/KernelSU-Next)** (`com.rifsxd.ksunext`, `v3.4.2`, `u:r:ksu:s0`) · **`13` active modules** (`Hybrid Mount`, `Zygisk Next`, `SUSFS`, `HMA-OSS`, `DisableApkVerification`, `HyperOS 4 Launcher Mod`, `Modded Security Center`, `NewUI Package Installer V3`, `FreeStyle Control Centre Mod`, `Xiaomi Dialer/InCallUI/Messages`, `HyperOS 4 Flagship Visual Unlock`, `HyperOS 4 90Hz Refresh Rate Unlock`, `HyperOS 4 5 Notification Icons`) *(all optional · custom modules at [POCO-X7-Pro-HyperOS4-KSU-Modules](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules))* |
| **Network / 5G & Telephony** | `ro.vendor.radio.5g = 3` (5G NSA+SA) · `preferred_network_mode = 33,33` · `power_center_5g_save_mode = 0` · **Native Xiaomi Phone, InCallUI & Messages active** via KSU module in `/system_ext/priv-app/` with `CallRecorderService` |
| **Live Verified Results** | **`130` total packages removed** (`126` via debloat: `30` `/cust` & `/product/data-app/` + `96` system including optional GetApps; plus `4` Google telephony/overlay packages replaced by the Xiaomi Dialer KSU module) + **`2` MTK voice services disabled**, **`0` resurrected**, **`0` `privapp` errors**, `traced` stopped, **`HOME = com.miui.home`**, **ART `speed` verified (`16/16` core + `38/38` user apps with DEX)**, **`7.64 GB` RAM available**, **`11.13 GB` free ZRAM (`3.27×`)**, **`120.00 Hz`**, **`0` crashes**, **`0` tombstones**, **`0` ANRs**, **`0` OOM/panics**, and **`0` active wakelocks**. |

---

## 0. Exact Installation & Setup Order (Step by Step)

Follow this exact order starting from a clean install of **HyperOS 4 EEA (`OS4.0.1.0.XOJEUXM`)** to reproduce the setup cleanly without errors or conflicts:

> **PC Requirements:** Windows with **PowerShell** and **`ADB` / `Fastboot`** ([Android Platform-Tools](https://developer.android.com/tools/releases/platform-tools)) available in `PATH`. To install it and automatically add it to `PATH` from PowerShell, run:
> ```powershell
> winget install Google.PlatformTools
> ```
> *(Close and reopen PowerShell afterwards so the updated `PATH` takes effect. The scripts automatically verify ADB connectivity and root permission for `Shell` before applying any changes.)*

1. **Install a clean HyperOS 4 EEA (`OS4.0.1.0.XOJEUXM`) ROM and complete initial boot:**
   * Update from stock `OS3.0.303.0.WOJEUXM` via the official updater (Mi Pilot / public OTA) or flash the official Fastboot ROM `.tgz` with Mi Flash Tool using **`clean all`** *(**NEVER** `clean all and lock`)*.
   * Once booted into `OS4.0.1.0.XOJEUXM`, perform a **Factory Reset** from *Settings → About phone → Factory reset* (using stock Android 17 recovery) and complete the initial setup wizard to reach the home screen.
2. **Flash the [EVONIX 4.6.1 Kernel](https://github.com/NEESCHAL-3/EVONIX-Kernel/) (`HyperOS -- KSU + SUSFS`):**
   * Officially compatible with **HyperOS 4 / Android 17** keeping the Linux `6.6.144` Android GKI base (`adios`, `bbr`, `schedutil`, KernelSU Next `v3.4.2`, and SUSFS `v2.4.0`).
   * If using the AnyKernel3 `.zip` package, boot into **Fastboot** and flash the **[HyperOS 4-specific OrangeFox (Telegram)](https://t.me/PocoX7ProNepalChat/93841)** to `vendor_boot` *(HyperOS 4 build released by [NEESCHAL-3](https://github.com/NEESCHAL-3) on Telegram; source repository and other releases at [GitHub — OrangeFox-rodin-source](https://github.com/NEESCHAL-3/OrangeFox-rodin-source/))* using two separate commands:
     1. `fastboot flash vendor_boot <ofox_hos4>.img`
     2. `fastboot reboot` — **as soon as you run this command, press and hold Volume Up (`Vol +`)** until the OrangeFox logo appears.
   * Once inside OrangeFox, flash the EVONIX 4.6.1 `.zip` *(no Format Data or wipes)* and reboot to system.
3. **Install the [KernelSU Next](https://github.com/KernelSU-Next/KernelSU-Next) manager (`v3.4.2`):**
   * Install the APK (`com.rifsxd.ksunext`), open it, and confirm it detects the EVONIX 4.6.1 kernel properly.
4. **Enable ADB debugging on the phone:**
   * Go to *Settings → About phone* (tap *OS version* 7 times) → *Additional settings → Developer options* and enable **USB debugging** and **USB debugging (Security settings)**.
5. **Grant root access to `Shell` (ADB) in KernelSU Next:**
   * Open **KernelSU Next → Superuser**, locate **`Shell`** (`com.android.shell`, UID `2000`), and toggle superuser permission on *(without this, `adb shell su -c ...` scripts cannot run)*.
6. **Run the initial deep debloat (without compiling ART yet) and reboot:**
   * Double-click **[Iniciar_Menu.bat](Iniciar_Menu.bat)** and choose **option `1`** *(or run `.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -SkipArtCompile`)* **before** installing your personal apps.
   * This removes `125` packages (`30` in `/cust` & `/product/data-app/` + `88` base system + `7` HOS 4 EEA-specific; the menu asks separately with explicit confirmation whether to keep or remove **GetApps** `com.xiaomi.mipicks` depending on whether you want to update system apps like `XMSF` first), disables the `2` MTK voice services, and applies `traced = 0` + `power_center_5g_save_mode = 0` *(leaving kernel, multitasking, and Google telephony untouched)*. **Reboot the device** when finished.
7. ***(Optional)* Configure KernelSU Next and install your desired modules/mods (base modules, native Xiaomi telephony, custom HyperOS 4 modules, and/or UI mods):**
   * Follow the complete step-by-step instructions in **[Section `2`](#2-stack-of-13-verified-kernelsu-next-modules-on-hyperos-4-eea-optional)** *(and its installation guide in **[Section `2.1`](#21-quick-guide-to-installing-modules-and-mods-on-kernelsu-next-optional)**)*. It covers the exact order and official links to disable **«Unmount modules by default»**, install **Hybrid Mount** *(mandatory for any module with a `system/` folder)*, add base modules (`Zygisk Next`, `SUSFS`, `HMA-OSS`), optionally install our 4 custom modules from **[POCO-X7-Pro-HyperOS4-KSU-Modules](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules)** (`Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA_v1.1-HOS4.zip`, `HyperOS4_Flagship_Visual_Unlock_rodin_v1.1.zip`, `HyperOS4_90Hz_Unlock_rodin_v1.0.zip`, and `HyperOS4_5_Notif_Icons_rodin_v1.0.zip`), and install `DisableApkVerification` plus Android 17-compatible UI mods *(including menu **option `4`** for the POCO fix on `HyperOS 4 Launcher Mod`)*.
8. **Install your personal apps and compile ART `speed` at the end:**
   * Once your final setup is installed, run **option `5`** in **[Iniciar_Menu.bat](Iniciar_Menu.bat)** *(or `.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyArtCompile -CompileUserApps`)* to compile all core + user apps to **ART `speed`** without uninstalling anything again.

---

## Repository Structure

```text
POCO-X7-Pro-HyperOS4-Debloat-Optimize/
├── README.md                                             # Complete guide in Spanish
├── README.en.md                                          # This complete guide in English (step-by-step, packages, links & audit)
├── Iniciar_Menu.bat                                      # Double-click on Windows: launches the interactive menu (no ExecutionPolicy issues)
└── scripts/
    ├── 00_menu_hos4_eea_evonix.ps1                       # Interactive console menu (options 1–9, D, R & ENTER to return)
    ├── 01_limpieza_y_optimizacion_hos4_eea_evonix.ps1    # Debloat (125 pkgs + optional GetApps) + POCO Launcher Fix + tweaks + ART speed
    └── 02_revertir_optimizaciones_hos4_eea.ps1           # Reverts system & 5G tweaks (Section 3) back to stock
```

> [!TIP]
> **Quick download (extract & run):** download **`POCO-X7-Pro-HyperOS4-Debloat-Optimize-Scripts_v1.0.zip`** from **[GitHub Releases](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-Debloat-Optimize/releases/latest)**, extract it anywhere, and double-click **`Iniciar_Menu.bat`**.

> [!NOTE]
> This repository hosts only the guide and scripts. The **4 custom KSU modules** built for this guide (`Xiaomi Dialer/InCallUI/Messages`, `HyperOS 4 Flagship Visual Unlock`, `HyperOS 4 90Hz Refresh Rate Unlock`, and `HyperOS 4 5 Notification Icons`) are hosted in their dedicated repository **[POCO-X7-Pro-HyperOS4-KSU-Modules](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules)** (uncompressed files + changelogs in the repo and flashable `.zip` builds in **[Releases](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases)**), while all third-party binaries (kernel, root manager, and mods) are downloaded directly from their official links in Section `0` and Section `2`.

---

## 1. Deep App Debloat (`125` base + `1` optional GetApps = up to `126` removed by script + `2` disabled)

**Recommended method (interactive menu):** double-click **[Iniciar_Menu.bat](Iniciar_Menu.bat)** *(or run `.\scripts\00_menu_hos4_eea_evonix.ps1` in PowerShell)*. It displays live ADB & Root status, orders options following the step-by-step workflow, prompts for confirmation on destructive actions *(including a dedicated prompt to keep or remove **GetApps**)*, and returns to the main menu on `ENTER`. *(Note: the interactive console UI of the scripts is in Spanish.)*

Underlying CLI script: **[01_limpieza_y_optimizacion_hos4_eea_evonix.ps1](scripts/01_limpieza_y_optimizacion_hos4_eea_evonix.ps1)**

> [!WARNING]
> **Read before running the full debloat (option `1`/`2`/`3` or script `01`):**
> * Run the full debloat **only on a clean install (before restoring your personal apps)**. If you already installed apps like Facebook, TikTok, Spotify, Netflix, LinkedIn, WPS Office, Booking, or Temu, the script will uninstall them unless you remove them from the list or use option `5` (`-OnlyArtCompile`).
> * The script removes **Google Chrome** and **Mi Browser** (you will have no browser until you install your preferred one from Play Store), as well as Gmail, Maps, YouTube, Google Photos, Google News, and Google Calendar *(**native Xiaomi Calendar** `com.xiaomi.calendar` is kept)*.
> * **GetApps (`com.xiaomi.mipicks`):** **kept by default** in case you need it to update system apps; only removed after explicit confirmation in the menu or passing `-RemoveGetApps` via CLI.
> * **Google telephony untouched by the script:** this script **does NOT remove** Google Phone, Messages, or Contacts because Xiaomi's native ones are absent from the EEA ROM. If you want native Xiaomi telephony apps, install the optional module `Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA.zip` (`v1.1-HOS4`, Step `7` / Section `2`), which **automatically removes Google's telephony apps** on boot after confirming all 3 Xiaomi apps mounted cleanly.
> * **Kernel and multitasking untouched:** this script **does not modify** EVONIX kernel parameters or RAM/ZRAM/LMKD/multitasking settings.

```powershell
# Easiest method — open the interactive console menu (or double-click Iniciar_Menu.bat):
.\scripts\00_menu_hos4_eea_evonix.ps1

# Direct CLI usage (advanced, in chronological order):
# 1. Step 6 — Initial debloat (125 apps + tweaks, keeps GetApps) WITHOUT compiling ART yet:
.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -SkipArtCompile

# 1B. Same as above, also removing GetApps (com.xiaomi.mipicks):
.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -SkipArtCompile -RemoveGetApps

# 2. Step 7 / Section 2.1 (optional, only if you installed HyperOS 4 Rust Launcher Mod on a POCO):
.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyFixRustLauncherPoco

# 3. Step 8 (at the end, after installing all your modules and personal apps — removes NOTHING):
.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyArtCompile -CompileUserApps

# Other optional flags (combinable):
#   -RemoveGetApps            Also removes GetApps (com.xiaomi.mipicks); kept by default
#   -SkipExtraHos4            Skips the 7 extra HOS4 EEA packages (keeps AICore, Google Calendar, etc.)
#   -SkipArtCompile           Skips ART speed compilation of core system/UI apps
#   -CompileUserApps          Also compiles all installed user apps (-3) to ART speed
#   -OnlyArtCompile           Skips debloat & tweaks; runs only ART speed compilation
#   -OnlyFixRustLauncherPoco  Patches hyperos_rust_launcher_mod for POCO (system.prop + MiLauncherGlobal whiteout + FINDER_ACCESS)
#   -Serial <id>              Target a specific ADB device if more than one is connected
```

### 1.1. Pre-Debloat Privacy Revocations & OTA Blocking (`3` settings)

| Command / Setting Applied | Value | Purpose & Reasoning |
|---|---|---|
| `settings put secure privacy_status_com.miui.msa.global 0` | `0` | Revokes **MIUI System Ads (MSA)** authorization before uninstalling, preventing the system from keeping an active ad consent flag. |
| `settings put secure miui_updater_enable 0` | `0` | Disables automatic Xiaomi OTA updater checks. |
| `settings put global ota_disable_automatic_update 1` | `1` | Blocks automatic background OTA downloads/updates (essential on rooted/custom-kernel devices). |

*(Note: unlike HyperOS 3 Global, `com.miui.daemon` and `com.mediatek.duraspeed` are no longer preinstalled on HyperOS 4 EEA `OS4.0.1.0.XOJEUXM`.)*

---

### 1.2. Preinstalled Apps in `/cust` & `/product/data-app/` Removed (`30`)

*(Removed during initial debloat to start clean; commercial apps can be reinstalled cleanly from Play Store and `/product/data-app/` apps can be restored without flashing the ROM following Section `5.1`.)*

#### Preinstalled Games (`9`)
| App Name | Package Name | Reason |
|---|---|---|
| Block Juggle | `com.block.juggle` | Promotional preinstalled game |
| Block Puzzle | `com.block.puzzle.game.hippo.mi` | Promotional preinstalled game |
| Jewels Blast | `com.jewelsblast.ivygames.Adventure.free` | Promotional preinstalled game |
| Eliminate Intruder 3D | `com.logame.eliminateintruder3d` | Promotional preinstalled game |
| Tile Fun (Triple Crush) | `com.mintgames.triplecrush.tile.fun` | Promotional preinstalled game |
| Word Trip | `com.mintgames.wordtrip` | Promotional preinstalled game |
| Snake (NF) | `com.nf.snake` | Promotional preinstalled game |
| Wood Blast | `com.ordinaryjoy.woodblast` | Promotional preinstalled game |
| Bubble Shooter | `com.sukhavati.gotoplaying.bubble.BubbleShooter.mint` | Promotional preinstalled game |

#### Preinstalled Commercial Apps (`9`)
| App Name | Package Name | Reason |
|---|---|---|
| WPS Office | `cn.wps.moffice_eng` | Promotional preinstalled office suite |
| WPS Office Lite (Xiaomi) | `cn.wps.xiaomi.abroad.lite` | Promotional lightweight WPS edition |
| Booking.com | `com.booking` | Promotional preinstalled app |
| Temu | `com.einnovation.temu` | Promotional shopping app |
| LinkedIn | `com.linkedin.android` | Promotional preinstalled app |
| Netflix | `com.netflix.mediaclient` | Promotional preinstalled app |
| Spotify | `com.spotify.music` | Promotional preinstalled app |
| Facebook | `com.facebook.katana` | Factory preinstalled *(reinstallable cleanly if used)* |
| TikTok | `com.zhiliaoapp.musically` | Factory preinstalled *(reinstallable cleanly if used)* |

#### Bloatware & Utilities in `/product/data-app/` (`12`)
| App Name | Package Name | What It Does |
|---|---|---|
| POCO Community | `com.mi.global.pocobbs` | POCO community forum |
| Mi Store | `com.mi.global.shop` | Official Xiaomi online store |
| Wallpaper Carousel OS4 | `com.miui.android.fashiongallery` | Rotates lockscreen wallpapers with news/ads (`MiGalleryLockScreenGlobalOs4`) |
| Mi Mover | `com.miui.huanji` | Initial phone-to-phone data migration tool |
| Xiaomi Home | `com.xiaomi.smarthome` | Xiaomi smart-home IoT controller |
| Mi Remote | `com.duokan.phone.remotecontroller` | IR blaster remote control |
| Compass | `com.miui.compass` | Compass utility |
| Mi Notes | `com.miui.notes` | Xiaomi notes app |
| Weather | `com.miui.weather2` | Weather app with content/suggestions |
| ShareMe (Mi Drop) | `com.xiaomi.midrop` | Local Xiaomi file transfer |
| Mi Scanner | `com.xiaomi.scanner` | Xiaomi QR & document scanner |
| Google News *(new in EEA)* | `com.google.android.apps.magazines` | Google News reader (`GoogleNews_arm64_xxhdpi`) |

*(**Kept** in `/product/data-app/`: Gallery Editor `com.miui.mediaeditor`, Calculator `com.miui.calculator`, Clock `com.android.deskclock`, Screen Recorder `com.miui.screenrecorder`, Voice Recorder `com.android.soundrecorder`, and Xiaomi Calendar `com.xiaomi.calendar`.)*

---

### 1.3. System Packages Removed by Script (`95` base + `1` optional GetApps = up to `96`) & Disabled MTK Services (`2`)

#### Ads, Telemetry, Auto-Installers & Factory Tests (`17`)
| App / Service Name | Package Name | What It Does |
|---|---|---|
| MIUI System Ads (MSA) | `com.miui.msa.global` | System ad engine in Xiaomi apps *(used ~184 MB idle RAM)* |
| MIUI Analytics | `com.miui.analytics` | Xiaomi analytics & telemetry collector *(used ~148 MB idle RAM)* |
| MiSight Service | `com.miui.misightservice` | Internal system telemetry & diagnostics |
| Bug Report | `com.miui.bugreport` | Captures & sends Xiaomi crash reports |
| Mi Service & Feedback | `com.miui.miservice` | Background Xiaomi support & feedback |
| Third-Party App Assistant | `com.miui.thirdappassistant` | Third-party app tracking/promotion |
| CatchLog | `com.bsp.catchlog` | Hardware debug log capturer |
| DebugLoggerUI | `com.debug.loggerui` | MediaTek engineering log UI |
| System Tracing (Traceur) | `com.android.traceur` | AOSP developer trace recording |
| Device Diagnostics | `com.android.devicediagnostics` | Android hardware diagnostics |
| ConfigurationClient (Kryten) | `com.wdstechnology.android.kryten` | Carrier OMA remote provisioning |
| Play Auto Installs (PAI) | `android.autoinstalls.config.Xiaomi.model` | Auto-installs carrier/OEM bloatware via Play Store |
| LocationEM2 | `com.mediatek.lbs.em2.ui` | MediaTek engineering GPS test menu |
| MDMConfig | `com.mediatek.mdmconfig` | MediaTek modem diagnostics |
| MDMLSample | `com.mediatek.mdmlsample` | MediaTek modem log test client |
| ATMWifiMeta | `com.mediatek.atmwifimeta` | MediaTek Wi-Fi factory test |
| JVFactoryTest (Fingerprint) | `com.jiiov.fingerprint_factorytest` | Fingerprint sensor factory test |

#### Xiaomi Bloatware, Stores, Cloud & OTA (`22` + `1` optional GetApps by confirmation)
| App / Service Name | Package Name | What It Does |
|---|---|---|
| GetApps (Mi Picks) *(optional)* | `com.xiaomi.mipicks` | Official Xiaomi app store *(**kept by default** in case you use it to update system apps; only removed after confirmation in the menu or via `-RemoveGetApps`)* |
| System Updater (OTA) | `com.android.updater` | Checks/downloads system OTA updates |
| System Apps Updater | `com.xiaomi.discover` | Updates Xiaomi apps outside Play Store |
| App Finder / Search | `com.mi.appfinder` | Global search with online suggestions |
| App Vault | `com.mi.globalminusscreen` | Left launcher screen with cards/news |
| Mi Browser | `com.mi.globalbrowser` | Xiaomi web browser with news feed |
| Mi Fitness / Health Global | `com.mi.healthglobal` | Xiaomi health & fitness tracker |
| Cleaner | `com.miui.cleaner` | Xiaomi cleaner powered by CleanMaster/ads |
| Frequent Phrases | `com.miui.phrase` | MIUI frequent text shortcuts |
| Mi Music | `com.miui.player` | Music player with online streaming/ads |
| Mi Video | `com.miui.videoplayer` | Video player with online feed/ads |
| Quick Ball | `com.miui.touchassistant` | Floating circular shortcut menu |
| Yellow Page | `com.miui.yellowpage` | MIUI commercial directory/caller lookup |
| Floating Notifications (Barrage) | `com.xiaomi.barrage` | Scrolling notifications over games |
| Game Center | `com.xiaomi.glgm` | Xiaomi game portal/store *(not Game Turbo)* |
| Tencent Soter Service | `com.tencent.soter.soterserver` | Biometric auth for Chinese payments (WeChat) |
| IFAA Service | `org.ifaa.aidl.manager` | Biometric auth for Chinese payments (Alipay) |
| MIUI Backup | `com.miui.backup` | Proprietary Xiaomi local backup |
| Xiaomi Cloud Backup | `com.miui.cloudbackup` | Automatic Xiaomi Cloud backups |
| Xiaomi Cloud | `com.miui.cloudservice` | Main Xiaomi Cloud service |
| Mi Cloud Sync | `com.miui.micloudsync` | Background Mi Cloud sync |
| Mi Cloud SDK | `com.xiaomi.micloud.sdk` | Xiaomi Cloud client library |
| Xiaomi SIM Activate Service | `com.xiaomi.simactivate.service` | Sends international SMS to activate SIM on Mi Cloud |

#### Meta & Microsoft System Services (`6`)
| App / Service Name | Package Name | What It Does |
|---|---|---|
| Meta App Installer | `com.facebook.system` | Silent background installer for Meta apps |
| Meta App Manager | `com.facebook.appmanager` | Background Meta updater outside Play Store |
| Meta Services | `com.facebook.services` | Persistent auxiliary Meta services |
| Link to Windows (AppManager) | `com.microsoft.appmanager` | Windows PC integration |
| Device Integration Service | `com.microsoft.deviceintegrationservice` | Windows linking background service |
| Cross-Device Service Broker | `com.microsoftsdk.crossdeviceservicebroker` | Microsoft cross-device bridge |

#### Xiaomi Interconnectivity / Cross-Device (`6`)
| App / Service Name | Package Name | What It Does |
|---|---|---|
| Mi Connect Service | `com.xiaomi.mi_connect_service` | Discovery & pairing with Xiaomi tablets/PCs |
| MiLink Service | `com.milink.service` | Wireless projection & MiLink transfer |
| Interconnectivity (Lyra SDK) | `com.xiaomi.continuity.sdkapp` | App continuity across Xiaomi devices |
| Xiaomi Mirror / Cast | `com.xiaomi.mirror` | Screen mirroring to Xiaomi PC/tablet |
| AutoUI Extension | `com.miui.autoui.ext` | Window layout adaptation for tablet/cast mode |
| Mi Share | `com.miui.mishare.connectivity` | Wi-Fi Direct sharing between Xiaomi/Oppo/Vivo |

#### Non-Essential HyperAI (`4`)
| App / Service Name | Package Name | What It Does |
|---|---|---|
| HyperAI Service | `com.xiaomi.aiservice` | Background AI assistant service |
| AI Vision | `com.xiaomi.aiasst.vision` | Xiaomi visual AI recognition |
| Mi AON Service | `com.xiaomi.aon` | Always-on front-camera gaze/presence detection |
| MIUI AICR | `com.xiaomi.aicr` | Local AI depth/layer detection engine *(used ~181 MB idle RAM; if depth wallpaper editing gets stuck on "Detecting layers", restore via `cmd package install-existing com.xiaomi.aicr`)* |

#### Unused AOSP, Printing & Accessibility (`10`)
| App / Service Name | Package Name | What It Does |
|---|---|---|
| Default Print Service | `com.android.bips` | Built-in AOSP Wi-Fi printing |
| Print Spooler | `com.android.printspooler` | Print job manager |
| Google Print Service Recommendation | `com.google.android.printservice.recommendation` | Printer plugin suggestions |
| Basic Daydreams | `com.android.dreams.basic` | Charging screensavers |
| Photo Screensavers | `com.android.dreams.phototable` | Idle photo collage screensaver |
| Android Easter Egg | `com.android.egg` | Hidden Android version mini-game |
| Bookmark Provider | `com.android.bookmarkprovider` | Legacy AOSP bookmarks |
| Partner Bookmarks | `com.android.providers.partnerbookmarks` | Carrier/OEM preset bookmarks |
| TalkBack | `com.google.android.marvin.talkback` | Voice accessibility screen reader |
| Switch Access | `com.google.android.accessibility.switchaccess` | External switch device control |

#### Google Telemetry & Optional Apps (`23`)
| App / Service Name | Package Name | What It Does |
|---|---|---|
| AdServices API | `com.google.android.adservices.api` | Privacy Sandbox / ad targeting |
| Mainline AdServices | `com.google.mainline.adservices` | Mainline Android Ads module |
| Mainline Telemetry | `com.google.mainline.telemetry` | Mainline telemetry module |
| Google Feedback | `com.google.android.feedback` | Sends feedback/error reports to Google |
| Location History | `com.google.android.gms.location.history` | Continuous Google location tracking |
| Google Partner Setup | `com.google.android.partnersetup` | Initial OEM/partner provisioning |
| Data Restore Tool | `com.google.android.apps.restore` | Initial migration from another phone |
| Digital Wellbeing | `com.google.android.apps.wellbeing` | Background screen-time tracker |
| Personal Safety | `com.google.android.apps.safetyhub` | Crash & emergency detection |
| Cross-Device Services | `com.google.ambient.streaming` | Cross-device app streaming |
| OK Google Enrollment | `com.android.hotwordenrollment.okgoogle` | Always-listening "OK Google" enrollment |
| Hey Google Enrollment | `com.android.hotwordenrollment.xgoogle` | Always-listening "Hey Google" enrollment |
| Google Chrome | `com.android.chrome` | Chrome browser *(WebView `150.0.7871.181` stays intact)* |
| YouTube | `com.google.android.youtube` | Official app *(optional; reinstallable from Play Store)* |
| YouTube Music | `com.google.android.apps.youtube.music` | Official app *(optional; reinstallable from Play Store)* |
| Google Photos | `com.google.android.apps.photos` | Google cloud gallery *(native Xiaomi Gallery is kept)* |
| Gmail | `com.google.android.gm` | Google email client |
| Google Maps | `com.google.android.apps.maps` | Google Maps |
| Google Drive | `com.google.android.apps.docs` | Cloud Drive client |
| Google One | `com.google.android.apps.subscriptions.red` | Google One subscriptions & backup |
| Google Meet | `com.google.android.apps.tachyon` | Google video calling |
| Google TV | `com.google.android.videos` | Google TV streaming/rentals |
| Android Auto | `com.google.android.projection.gearhead` | Car dashboard projection |

#### HyperOS 4 EEA / Android 17 Specific (`7` — *skippable with `-SkipExtraHos4`*)
| App / Service Name | Package Name | What It Does |
|---|---|---|
| Federated Compute | `com.google.android.federatedcompute` | Background Google federated ML training |
| On-Device Personalization | `com.google.android.ondevicepersonalization.services` | Android 17 Privacy Sandbox / local personalization |
| Android AICore | `com.google.android.aicore` | Local Gemini Nano OEM stub *(prevents multi-GB local model downloads; cloud Gemini `com.google.android.apps.bard` keeps working)* |
| Search Selector (EEA DMA) | `com.google.android.apps.setupwizard.searchselector` | EU search/browser picker used only during initial setup |
| MediaTek YGPS | `com.mediatek.ygps` | MediaTek engineering GPS satellite test tool |
| CameraTools Beta | `com.xiaomi.cameratools` | Camera debug log dumper (`DumpLogProvider`; does **not** affect native Camera) |
| Google Calendar | `com.google.android.calendar` | Duplicate app *(**Xiaomi Calendar** `com.xiaomi.calendar` and base provider are kept)* |

#### Optional Replacement of Google Phone / Messages / Contacts (Automatic When Installing the Xiaomi Telephony KSU Module)
*(**NOT part of the debloat script.** If you want native Xiaomi telephony apps on HyperOS 4 EEA, install the `Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA.zip` `v1.1-HOS4` module — Step `7` / Section `2`: on boot, after verifying all 3 Xiaomi apps loaded cleanly, the module itself automatically removes the `4` Google/overlay packages, sets the `DIALER`/`SMS` roles, and automatically restores them if you uninstall the module.)*

| Action | App Name | Package Name | Role / Function |
|---|---|---|---|
| **Removed** | Google Phone | `com.google.android.dialer` | Replaced by native Xiaomi dialer |
| **Removed** | Google Messages | `com.google.android.apps.messaging` | Replaced by native Xiaomi Messages |
| **Removed** | Google Contacts | `com.google.android.contacts` | Replaced by native Xiaomi Contacts |
| **Removed** | MIUI Google Phone Overlay | `com.android.phone.cust.overlay.miui` | Overlay forcing Google Dialer |
| **Active (KSU module)** | Xiaomi Phone & Contacts | `com.android.contacts` | Default **`DIALER`** role (`18.30.00.75`) |
| **Active (KSU module)** | Xiaomi InCallUI | `com.android.incallui` | Call screen + recorder (`40.01.63`, `targetSdk 37`) |
| **Active (KSU module)** | Xiaomi Messages Global | `com.android.mms` | Default **`SMS`** role (`18.0.0.54-gl`) |
| **Active (ROM)** | MTK Call Recorder | `com.mediatek.callrecorder` | `CallRecorderService` present |

#### Disabled MediaTek Voice Services (`pm disable-user --user 0`, `2`)
| Service Name | Package Name | What It Does & Why Disabled |
|---|---|---|
| MTK Voice Command | `com.mediatek.voicecommand` | MediaTek hardware voice command listener *(user-disabled without removing the `UID 1000` package)* |
| MTK Voice Unlock | `com.mediatek.voiceunlock` | MediaTek voice unlock (unused) |

---

### 1.4. Essential Kept Packages (HyperOS 4 EEA Red List)

| Name | Package | Why It Is Kept |
|---|---|---|
| POCO Launcher / HyperOS Launcher *(mod)* | `com.mi.android.globallauncher` / `com.miui.home` | Home screen, gestures & Recents (active `HOME`) |
| SystemUI Plugin / FreeStyle Control Centre *(mod)* | `miui.systemui.plugin` | Control Center & quick toggles |
| System UI | `com.android.systemui` | Status bar, notifications & lock screen |
| Xiaomi Security / Modded Security Center *(mod)* | `com.miui.securitycenter` | Permissions, battery, Game Turbo & core security |
| Security Add-on & Core | `com.miui.securityadd`, `com.miui.securitycore` | Game Turbo engine, floating windows & security services |
| PowerKeeper & PowerInsight *(HOS4)* | `com.miui.powerkeeper`, `com.miui.powerinsight` | Thermal profiles, refresh rate, power & battery stats |
| Joyose & GPU Game Driver *(MT6899)* | `com.xiaomi.joyose`, `com.mediatek.mt6989.gamedriver` | Thermal/gaming profiles & Dimensity 8400-Ultra GPU driver |
| TouchService & NovaJarvis | `com.xiaomi.touchservice`, `com.novatek.novavis` | Touch calibration & display processing |
| HyperComm, VsimCore & ModemTestBox | `com.xiaomi.hypercomm`, `com.miui.vsimcore`, `com.xiaomi.mtb` | HyperOS comms, modem/radio support & dormant `UID 1000` package |
| MIUI Global Layout | `com.mi.globallayout` | Global UI layout adaptation |
| Find Device | `com.xiaomi.finddevice` | Prevents bootloop on HyperOS *(never uninstall)* |
| Xiaomi Push (XMSF) | `com.xiaomi.xmsf` | System push notification framework |
| Gallery, HOS4 Plugin & Editor | `com.miui.gallery`, `com.hyper.gallery.plugin`, `com.miui.mediaeditor` | Native photo/video viewer, HOS4 plugin & editor |
| Camera & CameraMind *(HOS4)* | `com.android.camera`, `com.xiaomi.cameramind` | Native Xiaomi Camera & AI camera engine *(removing `cameramind` crashes Camera)* |
| File Manager & Calendar | `com.mi.android.globalFileexplorer`, `com.xiaomi.calendar` | Native Xiaomi file explorer & calendar |
| Active Telephony & HyperPhone Layer | `com.android.contacts`, `com.android.incallui`, `com.android.mms`, `com.mediatek.callrecorder`, `com.xiaomi.phone`, `com.xiaomi.incallui` | Native Xiaomi suite via KSU module *(if not using the KSU module, keep Google Phone/Messages/Contacts)* |
| Android Developer Verifier *(Android 17)* | `com.google.android.verifier` | Android 17 APK verification service *(removing it can break sideloading)* |
| Gboard & Gemini | `com.google.android.inputmethod.latin`, `com.google.android.apps.bard` | Default keyboard & cloud assistant |
| WebView, GMS, Play Store | `com.google.android.webview`, `com.google.android.gms`, `com.android.vending` | Web engine (`150.0.7871.181`), Play Services & Play Store |
| KernelSU Next | `com.rifsxd.ksunext` | Kernel-level root manager |

---

## 2. Stack of 13 Verified KernelSU Next Modules on HyperOS 4 EEA (Optional)

> [!NOTE]
> Installing **all of these modules is completely optional** (not only UI mods, but also mounting, Zygisk, hiding, Dialer, and custom unlocks). This list reflects the **complete stack used and live-verified** on HyperOS 4 EEA / Android 17 (SDK 37). All **4 custom modules** (`#10`–`#13`) are hosted with full changelogs at **[POCO-X7-Pro-HyperOS4-KSU-Modules](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules)**.

| # | Module (`id`) | Version | Verified Status / Purpose | Where to Get It |
|---:|---|---|---|---|
| 1 | **Hybrid Mount** (`hybrid_mount`) | `6.2.6` | Mounting metamodule (`OverlayFS` / `Magic Mount` / `VFS`) required in KernelSU Next v3+ (`9` `OverlayFS` mounts, `0` errors, `degraded = false`) | [GitHub — Hybrid-Mount/meta-hybrid_mount](https://github.com/Hybrid-Mount/meta-hybrid_mount) |
| 2 | **Zygisk Next** (`zygisksu`) | `1.5.3 (880)` | Standalone Zygisk injection for KernelSU (`[✅zygote, KernelSU 33365]`, `0` errors on Android 17) | [GitHub — Dr-TSNG/ZygiskNext](https://github.com/Dr-TSNG/ZygiskNext) |
| 3 | **SUSFS-FOR-KERNELSU** (`susfs4ksu`) | `v2.4.0-R28` | Hides root traces, mounts, and custom kernel (`status: ✅ SuS`, `verifiedboot = green`, `flash_locked = 1`) | [GitHub — sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) |
| 4 | **HMA-OSS Zygisk** (`hma_oss_zygisk`) | `oss-177` | *Hide My Applist OSS* Zygisk backend (`[✅ System service loaded]`, paired with the `org.frknkrc44.hma_oss` app); hides installed apps (root/mods) from other apps | [GitHub — frknkrc44/HMA-OSS](https://github.com/frknkrc44/HMA-OSS/) |
| 5 | **DisableApkVerification** (`DisableApkVerification`) | `v4` | Disables strict APK signature verification in `framework.jar`, `services.jar`, and `miui-services.jar` to allow modified system apps | [GitLab — mods-center/Apk-Signature-Verification-Patch](https://gitlab.com/mods-center/Apk-Signature-Verification-Patch) |
| 6 | **HyperOS 4 Launcher Mod (Rust/Flutter)** (`hyperos_rust_launcher_mod`) | `v1.4` | Replaces POCO Launcher with patched HyperOS 4 Launcher (`com.miui.home` `8.01.02.9258`, native dock, soft glass, widgets/icons) + `HyperLauncherExt` (`3.9`) *(on POCO requires running menu option `4`; if you prefer not to apply the fix, use [HyperOS-Launcher](https://gitlab.com/mods-center/HyperOS-Launcher) as an alternative)* | [GitLab — mods-center/HyperOS-Rust-Launcher-Mod](https://gitlab.com/mods-center/HyperOS-Rust-Launcher-Mod) · [Telegram — Mods Center](https://t.me/kashis_cringey_stuffs) |
| 7 | **Modded Security Center** (`security_app_mod`) | `v8` | Patched Security Center and Game Turbo (`com.miui.securitycenter` `13.8.0-261020.0.1`) | [GitLab — mods-center/HyperOS-Security-Center](https://gitlab.com/mods-center/HyperOS-Security-Center) |
| 8 | **NewUI Package Installer V3** (`newui_package_installer`) | `3.0` | Redesigned package installer (`com.google.android.packageinstaller` `17-15544436`, `targetSdk 37`) | [GitLab — mods-center/Package-Installer](https://gitlab.com/mods-center/Package-Installer) |
| 9 | **FreeStyle Control Centre Mod** (`freestyle_plugin_mod`) | `v1` | Customizable Control Center (`miui.systemui.plugin` `18.3.2.34.0`) | [GitLab — mods-center/FreeStyle-Control-Center](https://gitlab.com/mods-center/FreeStyle-Control-Center) |
| 10 | **Xiaomi Dialer, InCallUI & Messages** (`xiaomi_dialer_mms_hos4_eea`) | `v1.1-HOS4` | Installs native Xiaomi Phone/Contacts (`18.30.00.75`), InCallUI (`40.01.63` + call recorder), and Messages (`18.0.0.54-gl`) into `/system_ext/priv-app/` with `65` `privapp-permissions` for Android 17 (`enforce`). **On boot after installation, automatically removes Google telephony apps** (`Dialer`, `Messages`, `Contacts` + MIUI overlay) and sets `DIALER`/`SMS` roles *(and automatically restores them on uninstall; does NOT require `DisableApkVerification`)* | [Releases — `dialer-v1.1-HOS4`](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases/tag/dialer-v1.1-HOS4) · [Files](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/tree/main/Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA) |
| 11 | **HyperOS 4 Flagship Visual Unlock (`rodin`)** (`hos4_flagship_visual_rodin`) | `v1.1` | Unlocks via `resetprop -n` (without modifying system files, RAM/ZRAM, or kernel) **Advanced Textures**, **Liquid Glass (Bionic Material)** with **Classic / Transparent** picker in Settings, `GlassBloom`/`MiBloomStroke`, `MiBackgroundStyle` v5, animated **AGSL** music GPU shader, lockscreen Variable Fonts, and smooth freeform rotation animations *(Level 1 + Safe Level 2; requires neither `Hybrid Mount` nor `DisableApkVerification`)* | [Releases — `visual-v1.1`](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases/tag/visual-v1.1) · [Files](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/tree/main/HyperOS4_Flagship_Visual_Unlock_rodin) |
| 12 | **HyperOS 4 90Hz Refresh Rate Unlock (`rodin`)** (`hos4_90hz_unlock_rodin`) | `v1.0` | Dynamically patches `/product/etc/device_features/rodin.xml` at install time to add **`90 Hz`** alongside `60` and `120 Hz` under *Settings → Display & brightness → Refresh rate → Custom*, leveraging the AMOLED panel's native `90.0 Hz` hardware mode (`id=4`, `hwcId=3`) *(forward-compatible across updates; requires `Hybrid Mount`, does **not** require `DisableApkVerification`)* | [Releases — `refresh90hz-v1.0`](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases/tag/refresh90hz-v1.0) · [Files](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/tree/main/HyperOS4_90Hz_Unlock_rodin) |
| 13 | **HyperOS 4 5 Notification Icons (`rodin`)** (`hos4_5_notif_icons_rodin`) | `v1.0` | Installs a lightweight static RRO overlay in `/product/overlay/` (77 native locales, zero edits to `Settings.apk` or `MiuiSystemUI.apk`) replacing the status bar notification icon limit options (`None / 1 / 3`) with **`1 icon` / `3 icons` / `5 icons`** (`iconLimit=5` verified in `MiuiSystemUI`; requires `Hybrid Mount`, does **not** require `DisableApkVerification`) | [Releases — `notif5icons-v1.0`](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases/tag/notif5icons-v1.0) · [Files](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/tree/main/HyperOS4_5_Notif_Icons_rodin) |

*(Specific requirements: **SUSFS-FOR-KERNELSU** requires a SUSFS-enabled kernel such as EVONIX; **HMA-OSS Zygisk** requires **Zygisk Next** — module `#2` — plus its companion app `org.frknkrc44.hma_oss`; UI mods `#6` through `#9` require **DisableApkVerification** — module `#5` — installed and rebooted beforehand; custom modules `#10`, `#12`, and `#13` require **Hybrid Mount** — module `#1` — without needing `DisableApkVerification`, while `#11` requires neither.)*

> [!WARNING]
> **UI mod compatibility with Android 17 (SDK 37):** only use updated releases compatible with **HyperOS 4 / Android 17** (such as the versions listed above). Flashing older mods built for HyperOS 3 can cause `SystemUI` crashes or bootloops.

### 2.1. Quick Guide to Installing Modules and Mods on KernelSU Next (Optional)

> [!NOTE]
> This procedure applies **only to KernelSU / KernelSU Next** *(other root managers may require different steps)*.

1. **Disable «Unmount modules by default» *(mandatory for mounting system modules)*:**
   * Open **KernelSU Next → Settings tab** and disable **Unmount modules by default**.
2. **Install the Hybrid Mount metamodule *(mandatory in KernelSU Next v3+ for modules containing a `system/` folder)*:**
   * Download and install **[Hybrid Mount (`6.2.6`, Releases)](https://github.com/Hybrid-Mount/meta-hybrid_mount/releases)**, choose **OverlayFS** or **Magic Mount** *(**OverlayFS** typically has fewer issues, though both work)*, and **reboot**.
3. **Install base modules and *(optional)* the native Xiaomi telephony module:**
   * Install **[Zygisk Next (`1.5.3`)](https://github.com/Dr-TSNG/ZygiskNext/releases)**, **[SUSFS-FOR-KERNELSU (`v2.4.0-R28`)](https://github.com/sidex15/susfs4ksu-module/releases)**, and **[HMA-OSS](https://github.com/frknkrc44/HMA-OSS/releases)** *(if used)*, rebooting and verifying clean startup.
   * *(Optional — only if you want native Xiaomi telephony apps on EEA)* Download and install **[Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA_v1.1-HOS4.zip (Release `dialer-v1.1-HOS4`)](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases/tag/dialer-v1.1-HOS4)** and **reboot** *(requires Steps `1` and `2`, but does **not** require `DisableApkVerification`)*. This module installs Xiaomi **Phone/Contacts**, **InCallUI (with call recorder)**, and **Messages** into `/system_ext/priv-app/` with `65` `privapp` permissions for Android 17; on boot, after verifying all 3 Xiaomi apps loaded properly, it **automatically removes Google telephony apps** (`com.google.android.dialer`, `com.google.android.apps.messaging`, `com.google.android.contacts`, and `com.android.phone.cust.overlay.miui`) and assigns **`DIALER = com.android.contacts`** and **`SMS = com.android.mms`** *(and if you uninstall the module in KernelSU Next, it automatically restores Google's apps on reboot)*.
   * *(Optional — only if you want Advanced Textures + Liquid Glass and flagship animations on POCO X7 Pro)* Download and install **[HyperOS4_Flagship_Visual_Unlock_rodin_v1.1.zip (Release `visual-v1.1`)](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases/tag/visual-v1.1)** and **reboot** *(requires neither `Hybrid Mount` nor `DisableApkVerification`, and leaves RAM/ZRAM and kernel untouched)*. After rebooting, go to *Settings → Display & brightness → Advanced textures* to switch between **Transparent (Liquid Glass)** and **Classic**.
   * *(Optional — only if you want the native `90 Hz` option alongside `60` and `120 Hz` in Settings)* Download and install **[HyperOS4_90Hz_Unlock_rodin_v1.0.zip (Release `refresh90hz-v1.0`)](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases/tag/refresh90hz-v1.0)** and **reboot** *(requires Steps `1` and `2`, does **not** require `DisableApkVerification`, and dynamically patches `rodin.xml` at install time)*. After rebooting, **60 / 90 / 120 Hz** will appear under *Settings → Display & brightness → Refresh rate → Custom*.
   * *(Optional — only if you want up to `5` notification icons in the status bar)* Download and install **[HyperOS4_5_Notif_Icons_rodin_v1.0.zip (Release `notif5icons-v1.0`)](https://github.com/como-cuando-que/POCO-X7-Pro-HyperOS4-KSU-Modules/releases/tag/notif5icons-v1.0)** and **reboot** *(requires Steps `1` and `2`, does **not** require `DisableApkVerification`; lightweight static RRO overlay leaving `Settings.apk` and `SystemUI` untouched)*. After rebooting, **1 / 3 / 5 icons** will appear under *Settings → Notifications & status bar → Customize icon display*.
4. ***(Only if you want Android 17-compatible system UI mods — strictly requires Steps `1` and `2` above: «Unmount modules by default» disabled + Hybrid Mount installed and rebooted)*** **Install `DisableApkVerification` and your UI mods:**
   * Without both prerequisites (Steps `1` and `2`), system files from `DisableApkVerification` and UI mods will not mount.
   * First download and install the latest HyperOS 4-compatible version of **[DisableApkVerification (`v4`)](https://gitlab.com/mods-center/Apk-Signature-Verification-Patch)** and **reboot**.
   * Then install your desired UI mods from the table above (**[HyperOS 4 Launcher Mod](https://gitlab.com/mods-center/HyperOS-Rust-Launcher-Mod)**, **[Modded Security Center](https://gitlab.com/mods-center/HyperOS-Security-Center)**, **[NewUI Package Installer V3](https://gitlab.com/mods-center/Package-Installer)**, **[FreeStyle Control Centre Mod](https://gitlab.com/mods-center/FreeStyle-Control-Center)**), rebooting after installation.
5. ***(Only if installing HyperOS 4 Rust Launcher Mod `hyperos_rust_launcher_mod` on POCO)*** **Apply the POCO compatibility fix:**
   * On `POCO` devices, `PackageManagerServiceImpl.initIgnoreApps()` skips `/product/priv-app/MiuiHome` whenever `/product/priv-app/MiLauncherGlobal` exists (and both launchers share `14` `ContentProvider` authorities, so they cannot coexist).
   * After installing **[HyperOS 4 Launcher Mod (Rust/Flutter)](https://gitlab.com/mods-center/HyperOS-Rust-Launcher-Mod)** in KernelSU Next, open **[Iniciar_Menu.bat](Iniciar_Menu.bat)**, run **option `4`** *(or `.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyFixRustLauncherPoco`)*, and **reboot**. This non-destructively creates inside the module: `system.prop` (`ro.miui.product.home=com.miui.home`), the `MiLauncherGlobal/.remove` whiteout for Hybrid-Mount *(or standard `mknod c 0 0` on plain OverlayFS)*, appends `com.mi.appfinder.normal.permission.FINDER_ACCESS` to `privapp-permissions-com.miui.home-mod.xml` for Android 17 (`enforce`), and clears the stale scan cache.
   * If you later update `hyperos_rust_launcher_mod` to a newer build that still lacks native POCO support, simply run **option `4`** again before rebooting. To revert to POCO Launcher at any time, disable or remove the module in KernelSU Next and reboot.
   * **Alternative without applying the Rust Launcher fix:** if you prefer not to apply the patch for `hyperos_rust_launcher_mod`, you can use the traditional modded HyperOS Launcher instead from **[GitLab — mods-center/HyperOS-Launcher](https://gitlab.com/mods-center/HyperOS-Launcher)** *(do not install both launchers at the same time)*.

> [!IMPORTANT]
> **Always reboot after installing modules** and never mix UI mods without verifying Android 17 compatibility.

---

## 3. Active Tweaks & ART `speed` Compilation (Explained)

### 3.1. Persistent Tweaks Applied (Kernel & Multitasking Untouched)

| Command / Setting | Active Value | What It Does |
|---|---|---|
| `setprop persist.traced.enable 0` + `stop traced` + `stop traced_probes` | `0` (`stopped`) | Disables the **Perfetto** performance tracing daemon (`traced` and `traced_probes`), used only for developer profiling and consuming background RAM/CPU unnecessarily. |
| `settings put system power_center_5g_save_mode 0` | `0` | Disables HyperOS's aggressive 5G battery saver to prevent unnecessary downgrades from 5G to 4G when coverage is available. |
| `cmd package compile -m speed -f <package>` | `speed` | Ahead-of-time (**AOT**) compiles all app DEX code into native `arm64` machine code. Reduces CPU load, avoids on-the-fly JIT compilation, and improves app launch and animation smoothness. |

### 3.2. Verified ART `speed` Compilation Coverage (Post-Modules & Apps)
* **When to run:** once your final modules/mods and all personal apps are installed, run **option `5`** in **[Iniciar_Menu.bat](Iniciar_Menu.bat)** *(or `.\scripts\01_limpieza_y_optimizacion_hos4_eea_evonix.ps1 -OnlyArtCompile -CompileUserApps`)*. It does not uninstall anything and requires no reboot.
* **`16 / 16` core apps with DEX code verified in `arm64: [status=speed]` (`18 / 18` processed, `0` failures):** `miui.systemui.plugin` (Control Center), `com.android.systemui` (SystemUI), `com.android.settings` (Settings), `com.miui.securitycenter` (Security), `com.miui.securityadd` (Game Turbo), `com.google.android.packageinstaller` (Package Installer), `com.hyper.gallery.plugin` (HOS4 Gallery Plugin), `com.android.camera` (Camera), `com.android.contacts` (Xiaomi Phone/Contacts), `com.android.incallui` (Xiaomi InCallUI), `com.android.mms` (Xiaomi Messages), `com.miui.miwallpaper` (Wallpapers), `com.mi.android.globalFileexplorer` (File Manager), `com.google.android.inputmethod.latin` (Gboard), `com.xiaomi.calendar` (Calendar), and `com.miui.home.kashi.ext` (HyperLauncherExt) *(the other `2` present — Rust/Flutter `com.miui.home` and `com.miui.gallery` — have no compilable DEX code; the script covers `23` candidates and automatically skips absent ones)*.
* **`38 / 38` user apps with DEX code verified in `arm64: [status=speed]` (`40 / 40` processed, `0` failures):** all installed personal apps and games *(the `2` DEX-less Google helper packages — `com.google.android.contactkeys` and `com.google.android.safetycore` — do not require OAT compilation)*.

---

## 4. Live Audit Results on the Test Device (Full 13-Module Stack)

* **System & security:** **HyperOS 4 EEA (`OS4.0.1.0.XOJEUXM`)** · Android 17 (SDK 37 · patch `2026-11-01`) · **`6.6.144-EVONIX-HOS-V4.6.1`** · **SELinux `Enforcing`** · **`verifiedboot = green`** · **`flash_locked = 1`** *(with SUSFS `v2.4.0-R28` active)* · **`13 / 13` active KernelSU Next modules** (**Hybrid Mount `6.2.6`**: `OverlayFS`, `degraded = false`, `0` errors; **Zygisk Next `1.5.3`**, **SUSFS `v2.4.0-R28`**, **HMA-OSS `oss-177`** `[✅ System service loaded]`, **DisableApkVerification `v4`**, **HyperOS 4 Launcher Mod `v1.4`**, **Modded Security Center `v8`**, **NewUI Package Installer `3.0`**, **FreeStyle Control Centre `v1`**, **Xiaomi Dialer/InCallUI/Messages `v1.1-HOS4`**, **HyperOS 4 Flagship Visual Unlock `v1.1`** `[isBionicsEnabled=true, computilityLevel=2025-5, GLASS_FAILS=0]`, **HyperOS 4 90Hz Refresh Rate Unlock `v1.0`** `[modeId=4, 90.0 Hz]`, **HyperOS 4 5 Notification Icons `v1.0`** `[STATE_ENABLED, mPriority=61, iconLimit=5]`).
* **Deep stability:** **`0` crashes** (`FATAL = 0`, `native = 0`) · **`0` `privapp` errors** (privileged permissions for Launcher, Dialer/InCallUI/Messages, Security Center, and Package Installer all `granted=true`) · **`0` tombstones** · **`0` ANRs** · **`0` OOM / kernel panics** · **`0` active wakelocks** (`Wake Locks: size=0`).
* **CPU, RAM, ZRAM, I/O & display:**
  * **RAM (`11.03 GB` usable):** **`7.64 GB` available (`MemAvailable`)** (`2.45 GB` free + `4.72 GB` cached).
  * **ZRAM (`12 GB [lz4]`, `extm = 0`, `swappiness = 100`, `page-cluster = 3` — 100 % stock):** **`888 MB` used** compressed into **`271 MB` physical** (**`3.27×`** ratio) · **`11.13 GB` free**.
  * **EVONIX 4.6.1 kernel untouched:** UFS **`[adios]`** · TCP **`bbr`** · CPU **`schedutil`** (3 clusters).
  * **Display:** `1220×2712` **active at `120.00 Hz`** (`30 / 60 / 90 / 120 Hz`).
* **Debloat integrity, UI mods & native Xiaomi telephony:**
  * **`130 / 130` packages removed (`0` resurrected)** *(`126` via debloat including optional GetApps `com.xiaomi.mipicks` removed after updating `XMSF` to `6.2.67-G` + `4` Google telephony/overlay packages replaced by the Xiaomi module)* · **`2 / 2` MTK voice services disabled**.
  * `privacy_status_msa = 0`, `miui_updater_enable = 0`, `ota_disable_automatic_update = 1`, `traced = stopped`, `traced_probes = stopped`, `power_center_5g_save_mode = 0`, `preferred_network_mode = 33,33`.
  * **Active launcher & UI mods:** **`HOME = com.miui.home`** (`RELEASE-8.01.02.9258-261013-11132207-R`, `ro.miui.product.home = com.miui.home`, `/product/priv-app/MiLauncherGlobal` hidden via whiteout, `HyperLauncherExt 3.9` active) · **`Security Center`** (`13.8.0-261020.0.1`) · **`SystemUI Plugin`** (`18.3.2.34.0`) · **`Package Installer`** (`17-15544436`, `targetSdk 37`).
  * **Telephony & core components:** **`DIALER = com.android.contacts`** (`18.30.00.75`), **`InCallUI`** (`40.01.63`), **`SMS = com.android.mms`** (`18.0.0.54-gl`), **`CallRecorderService`** (`com.mediatek.callrecorder`), `IME = Gboard`, `WebView = 150.0.7871.181`.
  * **ART `speed` compilation completed (`0` failures):** **`16 / 16`** core apps with DEX (`18 / 18` processed; Rust/Flutter `com.miui.home` and `com.miui.gallery` without DEX) + **`38 / 38`** user apps with DEX (`40 / 40` processed; `2` DEX-less helper packages) verified in **`arm64: [status=speed]`**.

---

## 5. How to Revert Changes & Restore Any Uninstalled App

> [!TIP]
> All restore actions (including an **automatic numbered selector** for `/product/data-app/` apps), re-enabling MediaTek services, resetting ART, and reverting tweaks are built into **options `7` and `8` of [Iniciar_Menu.bat](Iniciar_Menu.bat)** ([00_menu_hos4_eea_evonix.ps1](scripts/00_menu_hos4_eea_evonix.ps1)).

### 5.1. Restore Any Uninstalled App

Depending on the package type removed, use the matching method *(no ROM reflash or data loss required)*:

1. **System apps & services (Section `1.3`, removed via `pm uninstall --user 0`):**
   ```powershell
   adb shell cmd package install-existing <package.name>
   ```
   *Examples:* `adb shell cmd package install-existing com.xiaomi.aicr` · `adb shell cmd package install-existing com.google.android.calendar`
   *(If you uninstall `Xiaomi_Dialer_InCallUI_Messages_HOS4_EEA.zip` `v1.1-HOS4` in KernelSU Next, it automatically restores `com.google.android.dialer`, `com.google.android.apps.messaging`, `com.google.android.contacts`, and `com.android.phone.cust.overlay.miui` on reboot; if you only disable it temporarily, you can restore them manually via `cmd package install-existing`.)*

2. **Preinstalled apps in `/product/data-app/` (Section `1.2`, such as Compass, Scanner, Notes, Weather, Mi Remote, ShareMe, Google News, etc.):**
   Their original signed APKs remain stored inside `/product/data-app/` on the ROM:
   ```powershell
   # 1. List original APK folders available on the ROM:
   adb shell "su -c 'ls /product/data-app/'"

   # 2. Check the exact .apk filename inside the chosen folder (example: Compass):
   adb shell "su -c 'ls /product/data-app/MIUICompassGlobal/'"

   # 3. Restore by installing the original APK and cleaning up the temp copy:
   adb shell "su -c 'cp /product/data-app/MIUICompassGlobal/MIUICompassGlobal.apk /data/local/tmp/app.apk && chmod 644 /data/local/tmp/app.apk && pm install /data/local/tmp/app.apk && rm -f /data/local/tmp/app.apk'"
   ```
   *(Replace `MIUICompassGlobal/MIUICompassGlobal.apk` with any other available app, e.g., `MiuiScanner/MiuiScanner.apk` for Scanner or `GoogleNews_arm64_xxhdpi/GoogleNews_arm64_xxhdpi.apk` for Google News.)*

3. **Commercial / third-party apps (Section `1.2`, such as Netflix, Spotify, Facebook, TikTok, etc.):**
   Reinstall clean, updated versions directly from **Google Play Store**.

4. **Re-enable the 2 disabled MediaTek voice services:**
   ```powershell
   adb shell "su -c 'pm enable com.mediatek.voicecommand && pm enable com.mediatek.voiceunlock'"
   ```

### 5.2. Revert Tweaks, Modules & ART Compilation

* **Revert system & 5G tweaks (Section `3`: `traced` and 5G saver):** run **[02_revertir_optimizaciones_hos4_eea.ps1](scripts/02_revertir_optimizaciones_hos4_eea.ps1)** and reboot *(this script does not revert the privacy revocations or OTA blocking from Section `1.1`)*.
* **Disable or remove any KSU module:** from **KernelSU Next → Modules** and reboot.
* **Reset ART compilation for an app (returns to standard Android profile):**
  ```powershell
  adb shell "su -c 'cmd package compile --reset <package.name>'"
  ```

---

## Credits & Acknowledgements

* Special thanks to **[NEESCHAL-3](https://github.com/NEESCHAL-3)** for his great work on the **[EVONIX Kernel](https://github.com/NEESCHAL-3/EVONIX-Kernel/)** and the **OrangeFox recovery for POCO X7 Pro (`rodin`)** ([GitHub repository](https://github.com/NEESCHAL-3/OrangeFox-rodin-source/) · [HyperOS 4 build on Telegram](https://t.me/PocoX7ProNepalChat/93841)). You can explore all of his projects and releases on GitHub: **[github.com/NEESCHAL-3](https://github.com/NEESCHAL-3)**.
