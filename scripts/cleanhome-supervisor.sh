#!/bin/sh
# Boot + watchdog: services, screensaver killers, and Clean Home without a Mac.

AMAZON_MODE="/data/cleanhome.amazon_mode"

# Fresh boot → amazon_mode default false (Clean Home). Session-only until Home.
rm -f "$AMAZON_MODE" /data/cleanhome.amazon_mode_ts \
  /data/cleanhome.home_pressed_ts /data/cleanhome.return_clean

ensure_killers() {
  /data/ensure-services.sh --no-launch
  if [ ! -f "$AMAZON_MODE" ]; then
    if ! ps -ef 2>/dev/null | grep '[f]iretv-booster.sh' | grep -q .; then
      setsid /data/firetv-booster.sh >/tmp/booster.log 2>&1 </dev/null &
    fi
  fi
  if ! ps -ef 2>/dev/null | grep '[f]iretv-home.sh' | grep -q .; then
    setsid /data/firetv-home.sh >/tmp/home.log 2>&1 </dev/null &
  fi
  # Opportunistic screensaver kill if killers lag.
  vlcm terminate-app --pkg-id com.amazon.screensaver --force >/dev/null 2>&1
}

for delay in 3 8 18 35 70; do
  sleep "$delay"
  ensure_killers
  if [ ! -f "$AMAZON_MODE" ]; then
    /data/launch-clean-home.sh
  fi
done

while true; do
  sleep 8
  ensure_killers
  if ! vlcm list 2>/dev/null | grep -q 'com.cleanhome.launcher.main'; then
    rm -f "$AMAZON_MODE"
    /data/launch-clean-home.sh
  elif [ ! -f "$AMAZON_MODE" ]; then
    # Only reclaim from screensaver when not in Amazon mode.
    # Do not yank VISIBLE smpl here — firetv-home owns smpl→Clean redirect;
    # racing launch-clean-home closed Amazon without Home.
    if vlcm list 2>/dev/null | grep 'com.amazon.screensaver' | grep -qw 'VISIBLE'; then
      vlcm terminate-app --pkg-id com.amazon.screensaver --force >/dev/null 2>&1
      if ! vlcm list 2>/dev/null | grep 'com.cleanhome.launcher.main' | grep -qw 'VISIBLE'; then
        /data/launch-clean-home.sh
      fi
    fi
  fi
done
