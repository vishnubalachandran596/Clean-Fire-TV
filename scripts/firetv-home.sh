#!/bin/sh
# Clean Home by default. While /data/cleanhome.amazon_mode exists, smpl→Clean redirect is on hold.
# Home from Amazon: vlcm HomeKey / smpl re-launch + async loggingctl stamp (firetv-home-logwatch.sh).

CLEAN_MAIN="com.cleanhome.launcher.main"
SMPL_MAIN="com.amazon.smplighthouse.launcher.main"
AMAZON_MODE="/data/cleanhome.amazon_mode"
RETURN_CLEAN="/data/cleanhome.return_clean"
HOME_PRESSED_TS="/data/cleanhome.home_pressed_ts"
# Avoid Clean↔smpl bounce after Home from Amazon.
LAUNCH_COOLDOWN_SEC=2
STREAM_KILL="com.amazon.screensaver com.netflix.kepler com.apple.atve.amazon.appletv com.suntv.sunnxt com.zee5.amazon com.onemainstream.sonyliv.android in.startv.hotstar tv.airtel.xstream.tvapp com.crunchyroll.crunchyroid com.amazon.frenchpress com.amazon.firetv.youtube com.amazon.music.kepler com.amazon.tahoe"

kill_streaming_on_home() {
  for pkg in $STREAM_KILL; do
    vlcm terminate-app --pkg-id "$pkg" --force >/dev/null 2>&1
  done
}

kill_screensaver_if_running() {
  echo "$1" | grep -E 'com\.amazon\.screensaver' | grep -q . || return 1
  vlcm terminate-app --pkg-id com.amazon.screensaver --force >/dev/null 2>&1
  return 0
}

home_key_signal() {
  echo "$1" | grep -qiE 'HomeKey|launchReason=[^ ]*[Hh]ome|wakeuphandler.*[Hh]ome|VegaTvLaunchDelegate.*[Hh]ome|homePressed'
}

back_key_signal() {
  echo "$1" | grep -qiE 'BackKey|launchReason=[^ ]*[Bb]ack'
}

# Soft background smpl — only when VISIBLE. Poking a NOT_VISIBLE wakeOnCrash
# instance every loop caused Clean↔Amazon reboot loops.
soft_smpl_background() {
  smpl_line=$(vlcm list 2>/dev/null | grep "$SMPL_MAIN" | head -1)
  echo "$smpl_line" | grep -qw "VISIBLE" || return 0
  smpl_inst=$(echo "$smpl_line" | tr -s ' ' | cut -d' ' -f4)
  [ -n "$smpl_inst" ] && vlcm trigger-app background --inst "$smpl_inst" >/dev/null 2>&1
}

bring_clean_home() {
  now=$(date +%s)
  if [ "$last_bring" -ne 0 ] && [ $((now - last_bring)) -lt "$LAUNCH_COOLDOWN_SEC" ]; then
    return 0
  fi
  # After leaving Amazon, pause yank so Home does not bounce Clean↔smpl.
  leave_ts=$(head -1 /data/cleanhome.leave_ts 2>/dev/null | tr -cd '0-9')
  if [ -n "$leave_ts" ] && [ $((now - leave_ts)) -lt 4 ] 2>/dev/null; then
    line=$(vlcm list 2>/dev/null | grep "$CLEAN_MAIN" | head -1)
    if echo "$line" | grep -qw "VISIBLE"; then
      return 0
    fi
  fi

  line=$(vlcm list 2>/dev/null | grep "$CLEAN_MAIN" | head -1)
  if echo "$line" | grep -qw "VISIBLE"; then
    return 0
  fi

  pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
  inst=$(echo "$line" | tr -s ' ' | cut -d' ' -f4)

  # pid 0 / IDLE is a stuck placeholder — terminate and re-send (do not no-op).
  if [ -n "$line" ] && [ "$pid" = "0" ]; then
    vlcm terminate-app --pkg-id com.cleanhome.launcher --force >/dev/null 2>&1
  fi

  soft_smpl_background

  last_bring=$now
  vmsgr send "pkg://$CLEAN_MAIN" >/dev/null 2>&1 \
    || vmsgr launch-app "pkg://$CLEAN_MAIN" >/dev/null 2>&1 \
    || vlcm launch-app "pkg://$CLEAN_MAIN" --singleton >/dev/null 2>&1
  line=$(vlcm list 2>/dev/null | grep "$CLEAN_MAIN" | head -1)
  pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
  inst=$(echo "$line" | tr -s ' ' | cut -d' ' -f4)
  if [ -n "$inst" ] && [ -n "$pid" ] && [ "$pid" != "0" ]; then
    vlcm trigger-app foreground --inst "$inst" >/dev/null 2>&1
  fi
}

ensure_clean_alive_background() {
  if vlcm list 2>/dev/null | grep -q "$CLEAN_MAIN"; then
    return 0
  fi
  vmsgr launch-app "pkg://$CLEAN_MAIN" >/dev/null 2>&1 \
    || vlcm launch-app "pkg://$CLEAN_MAIN" --singleton >/dev/null 2>&1
}

force_clean_visible() {
  last_bring=0
  bring_clean_home
  j=0
  while [ "$j" -lt 5 ]; do
    j=$((j + 1))
    vlcm list 2>/dev/null | grep "$CLEAN_MAIN" | grep -qw "VISIBLE" && return 0
    last_bring=0
    bring_clean_home
    sleep 0.2
  done
}

start_killer() {
  if ps -ef 2>/dev/null | grep '[f]iretv-booster.sh' | grep -q .; then
    return 0
  fi
  setsid /data/firetv-booster.sh >/tmp/booster.log 2>&1 </dev/null &
}

start_logwatch() {
  if ps -ef 2>/dev/null | grep '[f]iretv-home-logwatch.sh' | grep -q .; then
    return 0
  fi
  if [ -x /data/firetv-home-logwatch.sh ]; then
    setsid /data/firetv-home-logwatch.sh >/tmp/home-logwatch.log 2>&1 </dev/null &
  fi
}

exit_amazon_to_clean() {
  rm -f "$AMAZON_MODE" /data/cleanhome.amazon_mode_ts
  date +%s > /data/cleanhome.leave_ts
  # Bring Clean first; free RAM in background so Home is not blocked on terminates.
  force_clean_visible
  kill_streaming_on_home &
  start_killer
}

smpl_any_visible() {
  vlcm list 2>/dev/null | grep "$SMPL_MAIN" | grep -qw "VISIBLE"
}

publish_bridge_ip() {
  ip_addr=$(grep -B1 'host LOCAL' /proc/net/fib_trie 2>/dev/null \
    | grep -E '\|-- [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
    | grep -v 127. \
    | awk -F'|-- ' '{print $2}' \
    | head -1)
  if [ -n "$ip_addr" ]; then
    printf '%s' "$ip_addr" > /data/cleanhome.bridge_ip
  fi
}

# Grace after entering Amazon Home — smpl can take a few seconds to become VISIBLE
# while Clean is still briefly VISIBLE. Do not yank back during this window.
AMAZON_MODE_GRACE_SEC=8

amazon_mode_ready() {
  mode_ts=$(head -1 /data/cleanhome.amazon_mode_ts 2>/dev/null | tr -cd '0-9')
  now=$(date +%s)
  [ -n "$mode_ts" ] && [ $((now - mode_ts)) -ge "$AMAZON_MODE_GRACE_SEC" ] 2>/dev/null
}

last_bring=0
boot_done=0
prev_home_sig=0
prev_smpl_line=""
prev_smpl_vis=0

while true; do
  publish_bridge_ip
  start_logwatch

  if [ "$boot_done" -eq 0 ]; then
    boot_done=1
    # Reboot / daemon start → amazon_mode defaults to FALSE (file absent).
    # Dock "Amazon Home" sets it again; Home clears it. Never survive across boot.
    rm -f "$AMAZON_MODE" /data/cleanhome.amazon_mode_ts \
      "$HOME_PRESSED_TS" "$RETURN_CLEAN" /data/cleanhome.leave_ts
    # Brief settle so smpl wakeOnCrash + Clean do not thrash on every boot.
    sleep 2
    start_killer
    bring_clean_home
  fi

  RUNNING=$(vlcm list 2>/dev/null)
  clean_vis=0
  smpl_vis=0
  hud_vis=0
  echo "$RUNNING" | grep "$CLEAN_MAIN" | grep -qw "VISIBLE" && clean_vis=1
  smpl_any_visible && smpl_vis=1
  echo "$RUNNING" | grep 'com.amazon.vegatvsettings.hud' | grep -qw "VISIBLE" && hud_vis=1

  if kill_screensaver_if_running "$RUNNING"; then
    if [ ! -f "$AMAZON_MODE" ]; then
      start_killer
      bring_clean_home
    fi
    sleep 0.5
    continue
  fi

  if [ -f "$AMAZON_MODE" ]; then
    ensure_clean_alive_background
    RUNNING=$(vlcm list 2>/dev/null)
    echo "$RUNNING" | grep "$CLEAN_MAIN" | grep -qw "VISIBLE" && clean_vis=1 || clean_vis=0
    smpl_any_visible && smpl_vis=1 || smpl_vis=0
    smpl_line=$(echo "$RUNNING" | grep "$SMPL_MAIN" | head -1)

    home_sig=0
    home_key_signal "$RUNNING" && home_sig=1

    leave_amazon=0
    if [ -f "$RETURN_CLEAN" ]; then
      rm -f "$RETURN_CLEAN"
      leave_amazon=1
    fi
    if [ "$leave_amazon" -eq 0 ] && [ -f "$HOME_PRESSED_TS" ]; then
      ts=$(head -1 "$HOME_PRESSED_TS" 2>/dev/null | tr -cd '0-9')
      now=$(date +%s)
      mode_ts=$(head -1 /data/cleanhome.amazon_mode_ts 2>/dev/null | tr -cd '0-9')
      if [ -n "$ts" ] && [ -n "$mode_ts" ] && [ "$ts" -ge "$mode_ts" ] 2>/dev/null \
        && [ $((now - ts)) -le 20 ] 2>/dev/null; then
        leave_amazon=1
      fi
    fi

    # Rising edge: HomeKey / Home launchReason on vlcm — only after grace.
    # Do NOT leave on Back, Clean focus alone, or smpl line churn (those closed
    # Amazon Home without the user pressing Home).
    if [ "$leave_amazon" -eq 0 ] && [ "$home_sig" -eq 1 ] && [ "$prev_home_sig" -eq 0 ]; then
      if amazon_mode_ready; then
        leave_amazon=1
      fi
    fi

    # Home while already on Amazon: smpl VISIBLE + line change AND HomeKey on that line.
    if [ "$leave_amazon" -eq 0 ] && [ "$smpl_vis" -eq 1 ] && [ "$prev_smpl_vis" -eq 1 ]; then
      if [ -n "$smpl_line" ] && [ -n "$prev_smpl_line" ] && [ "$smpl_line" != "$prev_smpl_line" ]; then
        if home_key_signal "$smpl_line" && amazon_mode_ready; then
          leave_amazon=1
        fi
      fi
    fi

    prev_home_sig=$home_sig
    prev_smpl_line=$smpl_line
    prev_smpl_vis=$smpl_vis

    if [ "$leave_amazon" -eq 1 ]; then
      prev_home_sig=0
      prev_smpl_line=""
      prev_smpl_vis=0
      rm -f "$HOME_PRESSED_TS"
      exit_amazon_to_clean
      sleep 0.3
      continue
    fi

    sleep 0.15
    continue
  fi

  prev_home_sig=0
  prev_smpl_line=""
  prev_smpl_vis=0

  if home_key_signal "$RUNNING"; then
    kill_streaming_on_home
    start_killer
    bring_clean_home
    sleep 1
    continue
  fi

  if [ "$smpl_vis" -eq 1 ] && [ "$clean_vis" -eq 0 ]; then
    start_killer
    bring_clean_home
  elif back_key_signal "$RUNNING"; then
    start_killer
    bring_clean_home
  fi

  sleep 0.8
done
