# Agent instructions (Clean Home / fire-tv-launcher)

Before changing launcher, bridge, Home, or deploy behavior, read:

1. **[docs/ARCHITECTURE_AND_FINDINGS.md](docs/ARCHITECTURE_AND_FINDINGS.md)** — non-negotiable findings (VISIBLE vs NOT_VISIBLE, amazon_mode vs HUD, bridge IP, vmsgr, loggingctl).
2. **[docs/SETUP_FROM_SCRATCH.md](docs/SETUP_FROM_SCRATCH.md)** — end-to-end successful setup path.
3. **[docs/STICK_LAYOUT.md](docs/STICK_LAYOUT.md)** — where files live on the stick.
4. **[README.md](README.md)** — user-facing overview and deploy.

## Hard rules for agents

- Prefer **shell on `/data`** + **`vmsgr send`** for launches; do not assume RN `Linking` alone is enough for Amazon mode / Settings HUD.
- Use **`grep -qw VISIBLE`**, never bare `grep VISIBLE`.
- **Do not** set `amazon_mode` for the network HUD (`/network-panel`).
- **Do not** use `journalctl` for Home detection; use **`loggingctl`** (async logwatch) and/or `vlcm` HomeKey lines.
- Bridge: **LAN IP + `/data/cleanhome.bridge_ip` + 1s refresh**; loopback-only is insufficient for the RN app. Never ship `BRIDGE_IP_SEED=0.0.0.0` as a reachable host (reject unspecified / loopback).
- After script edits: push to `/data`, restart via `/data/start-booster.sh`, verify with `vlcm list` and `curl http://127.0.0.1:8765/...` from **adb shell**.
- Do not commit real device IPs as permanent config; deploy overwrites `src/bridgeIpSeed.ts`.
- `manifest.toml` `build-number` is required by Vega — do **not** climb forever. Sideload with **`1` ↔ `2` only** (`vpm install --force`). Uninstall first if the stick rejects a lower number.

## Required step — dock apps + original icons

When adding or fixing apps on the Clean Home dock, **always** do this checklist (do not stop at UI-only):

1. On the stick, list what is actually installed:  
   `vpm list components --category=com.amazon.category.kepler.media` **and**  
   `vpm list components --category=com.amazon.category.main`  
   (many apps, e.g. Crunchyroll / Xstream Play, are **not** in `kepler.media` alone).
2. Confirm live bridge list: `curl -s http://127.0.0.1:8765/apps` — every user streaming/music app that is installed must appear with a real `iconUrl` (`m.media-amazon.com/images/I/…`, not ads-system).
3. Update **`scripts/launcher-api-handler.sh`**: `icon_url_for_pkg`, `list_apps_json` (categories + `emit_app_if_installed` known pkgs), keep Settings / Amazon Home pinned last.
4. Update **`src/App.tsx`**: `BUNDLED_ICONS` + `SEED_MEDIA_APPS` for offline/seed dock.
5. Add **`assets/icons/<packageId>.png`** (512² Appstore art) and `assets/icons/asin_icon_urls.json`.
6. Add package to **`STREAM_KILL` / `STREAM_BG`** in `firetv-home.sh` / `firetv-booster.sh` when it should free RAM on Home.
7. Deploy: `./boost-firetv.sh <STICK_IP>` + rebuild/install vpkg; re-check `/apps` and dock OK launch.

Known packages: Crunchyroll `com.crunchyroll.crunchyroid`, Xstream Play `tv.airtel.xstream.tvapp`, Amazon Music `com.amazon.music.kepler` (include when installed).

Cursor rule mirror: `.cursor/rules/firetv-clean-home.mdc`.
