#!/bin/sh
# Async Home detector for Amazon mode — loggingctl is slow, so it runs out-of-band
# and stamps /data/cleanhome.home_pressed_ts for firetv-home.sh to consume.

AMAZON_MODE="/data/cleanhome.amazon_mode"
HOME_PRESSED_TS="/data/cleanhome.home_pressed_ts"
AMAZON_MODE_TS="/data/cleanhome.amazon_mode_ts"

while true; do
  if [ -f "$AMAZON_MODE" ]; then
    mode_ts=$(head -1 "$AMAZON_MODE_TS" 2>/dev/null | tr -cd '0-9')
    now=$(date +%s)
    # Ignore logs from the moment we entered Amazon.
    if [ -n "$mode_ts" ] && [ $((now - mode_ts)) -ge 1 ] 2>/dev/null; then
      if loggingctl log -S "1 seconds ago" 2>/dev/null \
        | grep -qiE 'HomeKey|homePressed|KEY_HOME|launchReason=[^ ]*[Hh]ome|VegaTvLaunchDelegate.*[Hh]ome'; then
        date +%s > "$HOME_PRESSED_TS"
      fi
    fi
    sleep 0.3
  else
    sleep 1
  fi
done
