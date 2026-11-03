# Setup from scratch (successful path)

This is the direct path that reaches the **current Clean Home** state on a Vega / Fire TV Stick HD. Retries and dead ends are omitted.

## 1. Amazon developer account & device

1. Create / sign in to an [Amazon Developer](https://developer.amazon.com/) account.
2. Enable **developer mode** on the Fire TV Stick HD (Vega OS).
3. Note the stick’s LAN IP (Settings → Network, or your router).
4. Enable ADB networking on the stick (developer options). From a Mac:

```bash
adb connect <STICK_IP>:5555
adb devices   # must show device
```

## 2. Vega / Kepler CLI on the Mac

1. Install the Amazon **Vega SDK** / Kepler toolchain for your OS (follow current Amazon Vega docs for your SDK version).
2. Ensure `vega`, `vpt` / `vtbuild`, and related tools are on `PATH` (often via a `source ~/vega/env` or SDK `bin/tools` path).
3. Install Node.js **≥ 20**.
4. Android `platform-tools` (`adb`) on `PATH`.

## 3. Project install & build

```bash
cd FiretvHD   # or your clone of fire-tv-launcher
npm install
npm run build:release
```

Armv7 package (typical Stick HD):

`build/private/kepler/@amazon-devices/leanlauncher/0.1/vega/armv7/Release/@amazon-devices/leanlauncher_armv7.vpkg`

## 4. On-stick shell services (persistent under `/data`)

Push and start (or use `./boost-firetv.sh <STICK_IP>`):

| Host file | Stick path | Role |
|-----------|------------|------|
| `scripts/launcher-api-handler.sh` | `/data/launcher-api-handler.sh` | HTTP bridge on **:8765** (inetd via `systemd-socket-activate`) |
| `scripts/firetv-home.sh` | `/data/firetv-home.sh` | Default launcher redirect, Home handling, screensaver |
| `scripts/firetv-home-logwatch.sh` | `/data/firetv-home-logwatch.sh` | Async Home detection via `loggingctl` |
| `scripts/firetv-booster.sh` | `/data/firetv-booster.sh` | Screensaver kill; background streaming cleanup |
| `scripts/ensure-services.sh` | `/data/ensure-services.sh` | Start missing daemons |
| `scripts/start-booster.sh` | `/data/start-booster.sh` | Full restart of bridge + daemons + Clean Home |
| `scripts/launch-clean-home.sh` | `/data/launch-clean-home.sh` | Foreground Clean Home |
| `scripts/cleanhome-supervisor.sh` | `/data/cleanhome-supervisor.sh` | Watchdog after boot |

```bash
adb -s <STICK_IP>:5555 push scripts/*.sh /data/
adb -s <STICK_IP>:5555 shell 'chmod +x /data/*.sh; /data/start-booster.sh'
```

Bridge listen:

```text
systemd-socket-activate -l 8765 -a --inetd /data/launcher-api-handler.sh
```

## 5. Install the vpkg

```bash
adb -s <STICK_IP>:5555 push <path-to>_armv7.vpkg /tmp/leanlauncher_armv7.vpkg
adb -s <STICK_IP>:5555 shell 'vpm install /tmp/leanlauncher_armv7.vpkg --force'
adb -s <STICK_IP>:5555 shell 'vmsgr send pkg://com.cleanhome.launcher.main'
```

Package id: `com.cleanhome.launcher`  
Main component: `com.cleanhome.launcher.main`  
Boot task: `com.cleanhome.launcher.boot` (headless; scheduled on install)  
Manifest privileges: `com.amazon.network.privilege.network-access`, `com.amazon.background-tasks.privilege.run`

After a successful vpkg install, the install task schedules a durable repeating boot job so
**reboot should not require Mac `boost-firetv.sh`** as long as `/data/*.sh` still exist.

## 6. Verify current behavior

```bash
adb -s <STICK_IP>:5555 shell '
  curl -s http://127.0.0.1:8765/ping
  curl -s http://127.0.0.1:8765/screen-stats-fast
  vlcm list | grep -E "cleanhome|VISIBLE"
  ps -ef | grep -E "firetv-home|firetv-booster|8765" | grep -v grep
'
```

Expected:

- Clean Home **VISIBLE** when not in Amazon mode.
- Bridge returns JSON metrics.
- Daemons listed above are running.

## 6b. First-setup icons (on the TV)

Do this once on a fresh stick (also summarized in README Step 7):

1. Stick online (Wi‑Fi) so Appstore CDN icons can load (`m.media-amazon.com`).
2. Install streaming apps from the Amazon Appstore — `/apps` only lists installed media components.
3. Launch Clean Home so it can pull `/apps` and merge original icons (bundled `assets/icons/com.*.png` + bridge `iconUrl`).
4. Missing art → title tile until you add `assets/icons/<packageId>.png`, `BUNDLED_ICONS`, and `icon_url_for_pkg` in `launcher-api-handler.sh`, then rebuild + `./boost-firetv.sh <STICK_IP>`.

Package dirs are sandboxed — you cannot scrape icons from `/pkgs` for the RN dock.

## 7. Flags & control files on stick

| Path | Meaning |
|------|---------|
| `/data/cleanhome.amazon_mode` | Pause smpl→Clean redirect (Amazon Home session) |
| `/data/cleanhome.amazon_mode_ts` | When Amazon mode started |
| `/data/cleanhome.home_pressed_ts` | Home press stamp (logwatch / app) |
| `/data/cleanhome.bridge_ip` | Published LAN IP for the RN bridge |
| `/data/cleanhome.launch_cooldown` | Pause streaming kills after dock launch |

Useful bridge routes: `/ping`, `/screen-stats-fast`, `/launch/<component>`, `/amazon-home`, `/network-panel`, `/home-to-clean`, `/resume-default`.
