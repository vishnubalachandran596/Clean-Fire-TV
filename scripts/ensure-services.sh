#!/bin/sh
# Start missing Clean Home services (no kill if already running).

start_one() {
  pattern="$1"
  shift
  if ps -ef 2>/dev/null | grep "$pattern" | grep -v grep | grep -q .; then
    return 0
  fi
  setsid "$@" >/dev/null 2>&1 </dev/null &
  return 0
}

# Keep bridge LAN IP fresh for the app (DHCP / Wi‑Fi changes).
IP=$(grep -B1 'host LOCAL' /proc/net/fib_trie 2>/dev/null \
  | grep -E '\|-- [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | grep -v 127. \
  | awk -F'|-- ' '{print $2}' \
  | head -1)
[ -n "$IP" ] && printf '%s' "$IP" > /data/cleanhome.bridge_ip

start_one 'systemd-socket-activate.*8765' \
  systemd-socket-activate -l 8765 -a --inetd /data/launcher-api-handler.sh

start_one '[f]iretv-home.sh' /data/firetv-home.sh
start_one 'firetv-home-logwatch.sh' /data/firetv-home-logwatch.sh

# Screensaver killer always runs; it no-ops streaming kills while amazon_mode is set.
start_one 'firetv-booster.sh' /data/firetv-booster.sh

start_one 'cleanhome-supervisor.sh' /data/cleanhome-supervisor.sh

if [ "$1" != "--no-launch" ] && [ ! -f /data/cleanhome.amazon_mode ]; then
  /data/launch-clean-home.sh
fi
