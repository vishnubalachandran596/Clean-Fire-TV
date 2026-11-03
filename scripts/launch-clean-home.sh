#!/bin/sh
# Bring Clean Home forward when not in Amazon mode (boot / recovery).
# Soft handoff only — hard-kill smpl caused Clean↔Amazon wakeOnCrash loops.

AMAZON_MODE="/data/cleanhome.amazon_mode"
CLEAN_MAIN="com.cleanhome.launcher.main"
SMPL_MAIN="com.amazon.smplighthouse.launcher.main"

[ -f "$AMAZON_MODE" ] && exit 0

if ! ps -ef 2>/dev/null | grep '[f]iretv-booster.sh' | grep -q .; then
  setsid /data/firetv-booster.sh >/tmp/booster.log 2>&1 </dev/null &
fi

line=$(vlcm list 2>/dev/null | grep "$CLEAN_MAIN" | head -1)
if [ -n "$line" ] && echo "$line" | grep -qw "VISIBLE"; then
  exit 0
fi

pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
inst=$(echo "$line" | tr -s ' ' | cut -d' ' -f4)

if [ -n "$line" ] && [ "$pid" = "0" ]; then
  vlcm terminate-app --pkg-id com.cleanhome.launcher --force >/dev/null 2>&1
fi

smpl_line=$(vlcm list 2>/dev/null | grep "$SMPL_MAIN" | head -1)
smpl_inst=$(echo "$smpl_line" | tr -s ' ' | cut -d' ' -f4)
# Only background smpl when VISIBLE (avoid wakeOnCrash loops).
if echo "$smpl_line" | grep -qw "VISIBLE"; then
  [ -n "$smpl_inst" ] && vlcm trigger-app background --inst "$smpl_inst" >/dev/null 2>&1
fi

i=0
while [ "$i" -lt 5 ]; do
  i=$((i + 1))
  line=$(vlcm list 2>/dev/null | grep "$CLEAN_MAIN" | head -1)
  if echo "$line" | grep -qw "VISIBLE"; then
    exit 0
  fi
  pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
  inst=$(echo "$line" | tr -s ' ' | cut -d' ' -f4)
  if [ -n "$line" ] && [ "$pid" = "0" ]; then
    vlcm terminate-app --pkg-id com.cleanhome.launcher --force >/dev/null 2>&1
  fi
  vmsgr send "pkg://$CLEAN_MAIN" >/dev/null 2>&1 \
    || vmsgr launch-app "pkg://$CLEAN_MAIN" >/dev/null 2>&1 \
    || vlcm launch-app "pkg://$CLEAN_MAIN" --singleton >/dev/null 2>&1
  line=$(vlcm list 2>/dev/null | grep "$CLEAN_MAIN" | head -1)
  pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
  inst=$(echo "$line" | tr -s ' ' | cut -d' ' -f4)
  if [ -n "$inst" ] && [ -n "$pid" ] && [ "$pid" != "0" ]; then
    vlcm trigger-app foreground --inst "$inst" >/dev/null 2>&1
  fi
  sleep 0.4
done
