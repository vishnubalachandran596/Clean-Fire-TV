#!/usr/bin/env bash
# Deploy on-stick scripts and restart Clean Home services.
# Usage: ./boost-firetv.sh [STICK_LAN_IP]
set -euo pipefail

export PATH="${HOME}/vega/sdk/vega-sdk/main/2.0.13986/bin/tools:${HOME}/vega/bin:${HOME}/Library/Android/sdk/platform-tools:${PATH}"
FIRETV_IP="${1:?Usage: $0 <STICK_LAN_IP>}"
DEV="${FIRETV_IP}:5555"
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Connecting to Fire TV at $DEV..."
adb connect "$DEV" >/dev/null 2>&1 || true

SEED="$ROOT/src/bridgeIpSeed.ts"
cat > "$SEED" <<EOF
/**
 * Bootstraps the bridge LAN host when loopback fetch is blocked in the app sandbox.
 * Updated by deploy scripts from the stick's current IP — not a permanent DHCP pin.
 * Runtime discovery refreshes every 1s and overrides this when Wi‑Fi changes.
 */
export const BRIDGE_IP_SEED = '${FIRETV_IP}';
EOF

echo "Deploying scripts to /data ..."
# Some sticks reject adb push straight to /data — stage via /tmp then cp.
stage_script() {
  local src="$1" name="$2"
  adb -s "$DEV" push "$src" "/tmp/$name" >/dev/null
  adb -s "$DEV" shell "cp /tmp/$name /data/$name && chmod +x /data/$name"
}
stage_script "$ROOT/scripts/firetv-booster.sh" firetv-booster.sh
stage_script "$ROOT/scripts/firetv-home.sh" firetv-home.sh
stage_script "$ROOT/scripts/firetv-home-logwatch.sh" firetv-home-logwatch.sh
stage_script "$ROOT/scripts/ensure-services.sh" ensure-services.sh
stage_script "$ROOT/scripts/cleanhome-supervisor.sh" cleanhome-supervisor.sh
stage_script "$ROOT/scripts/launcher-api-handler.sh" launcher-api-handler.sh
stage_script "$ROOT/scripts/start-booster.sh" start-booster.sh
stage_script "$ROOT/scripts/launch-clean-home.sh" launch-clean-home.sh
adb -s "$DEV" shell '/data/start-booster.sh'

# Nudge the package boot path (install task + headless boot). Safe if the new
# vpkg is not installed yet — vmsgr/vtm will no-op or error without harming /data.
adb -s "$DEV" shell 'vmsgr send pkg://com.cleanhome.launcher.boot >/dev/null 2>&1 || true'

adb -s "$DEV" shell 'vlcm terminate-app --pkg-id com.amazon.screensaver --force >/dev/null 2>&1; echo OK; ps -ef | grep -E "firetv-home|firetv-booster|logwatch|8765" | grep -v grep; free -m | head -2'
echo "Done. Rebuild/install the vpkg separately if the RN app changed."
echo "Note: after installing a vpkg with the boot task, reboot no longer needs this script — /data scripts + package headless boot keep services up."
