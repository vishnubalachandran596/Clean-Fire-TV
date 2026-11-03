#!/bin/sh
# Kill screensaver flashes + background streaming.
# Never kill a VISIBLE app (that is the one the user just opened).
# Respect /data/cleanhome.launch_cooldown after dock launches.

AMAZON_MODE="/data/cleanhome.amazon_mode"
LAUNCH_COOLDOWN="/data/cleanhome.launch_cooldown"
CLEAN_MAIN="com.cleanhome.launcher.main"
STREAM_BG="com.netflix.kepler com.apple.atve.amazon.appletv com.suntv.sunnxt com.zee5.amazon com.onemainstream.sonyliv.android in.startv.hotstar tv.airtel.xstream.tvapp com.crunchyroll.crunchyroid com.amazon.frenchpress com.amazon.firetv.youtube com.amazon.music.kepler com.amazon.tahoe"

kill_screensaver() {
  RUNNING="$1"
  echo "$RUNNING" | grep -E 'com\.amazon\.screensaver' | grep -q . || return 1
  vlcm terminate-app --pkg-id com.amazon.screensaver --force >/dev/null 2>&1
  return 0
}

launch_cooldown_active() {
  [ -f "$LAUNCH_COOLDOWN" ] || return 1
  ts=$(head -1 "$LAUNCH_COOLDOWN" 2>/dev/null | tr -cd '0-9')
  [ -n "$ts" ] || return 1
  now=$(date +%s)
  # 12s window after a dock launch so the target app can become VISIBLE.
  [ $((now - ts)) -le 12 ] 2>/dev/null
}

# Only terminate streaming pkgs that are present but NOT visible.
kill_background_streaming() {
  RUNNING=$(vlcm list 2>/dev/null)
  for pkg in $STREAM_BG; do
    line=$(echo "$RUNNING" | grep "$pkg" | head -1)
    [ -n "$line" ] || continue
    echo "$line" | grep -qw "VISIBLE" && continue
    vlcm terminate-app --pkg-id "$pkg" --force >/dev/null 2>&1
  done
}

while true; do
  RUNNING=$(vlcm list 2>/dev/null)

  # Always kill screensaver — even in Amazon mode.
  if kill_screensaver "$RUNNING"; then
    sleep 0.25
    continue
  fi

  if [ -f "$AMAZON_MODE" ]; then
    sleep 1
    continue
  fi

  if launch_cooldown_active; then
    sleep 0.5
    continue
  fi

  if echo "$RUNNING" | grep "$CLEAN_MAIN" | grep -qw "VISIBLE"; then
    kill_background_streaming
    sleep 3
    continue
  fi

  sleep 0.8
done
