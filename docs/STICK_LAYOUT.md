# On-stick file layout

All operational scripts live under **`/data`** (writable, survives reboot on Stick HD).

```text
/data/
  launcher-api-handler.sh    # HTTP API (spawned per request by inetd)
  firetv-home.sh             # Main home / redirect loop
  firetv-home-logwatch.sh    # Async Home log watcher
  firetv-booster.sh          # Screensaver + background app cleaner
  ensure-services.sh         # Start missing services
  start-booster.sh           # Full restart entrypoint
  launch-clean-home.sh       # Foreground Clean Home
  cleanhome-supervisor.sh    # Boot / watchdog
  cleanhome.bridge_ip        # Current LAN IP (written by scripts)
  cleanhome.amazon_mode      # Present while Amazon Home session is active
  cleanhome.amazon_mode_ts
  cleanhome.home_pressed_ts
  cleanhome.launch_cooldown
  cleanhome.speed_mbps       # Cached speed for fast metrics
  ...
```

Installed app (package manager):

```text
com.cleanhome.launcher
  ├── com.cleanhome.launcher.main                      # launcher + main category
  ├── com.cleanhome.launcher.boot                      # headless: ensure /data services
  └── com.cleanhome.launcher.onInstallOrUpdateTask     # schedules durable boot on install
```

After install, Task Manager persists a repeating `cleanhome-boot-ensure` job (every ~120s,
`persistAfterAppDeath`). On reboot it re-runs the boot task so Mac `boost-firetv.sh` is not
required just to bring `:8765` / home / booster / supervisor back.

Runtime processes to expect:

```text
systemd-socket-activate -l 8765 -a --inetd /data/launcher-api-handler.sh
sh /data/firetv-home.sh
sh /data/firetv-home-logwatch.sh
sh /data/firetv-booster.sh
sh /data/cleanhome-supervisor.sh   # optional watchdog
```
