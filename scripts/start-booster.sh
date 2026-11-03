#!/bin/sh
# Clear Amazon pause and (re)start Clean Home services — used after reboot / Mac deploy.
# amazon_mode always starts false; only dock Amazon Home sets it until remote Home.
rm -f /data/cleanhome.amazon_mode /data/cleanhome.amazon_mode_ts \
  /data/cleanhome.home_pressed_ts /data/cleanhome.return_clean
ps -ef | grep firetv-booster.sh | grep -v grep | awk '{print $2}' | xargs -r kill -9
ps -ef | grep firetv-home-logwatch.sh | grep -v grep | awk '{print $2}' | xargs -r kill -9
ps -ef | grep '[f]iretv-home.sh' | grep -v grep | awk '{print $2}' | xargs -r kill -9
ps -ef | grep cleanhome-supervisor.sh | grep -v grep | awk '{print $2}' | xargs -r kill -9
ps -ef | grep "systemd-socket-activate" | grep -v grep | awk '{print $2}' | xargs -r kill -9
sleep 0.3
IP=$(grep -B1 'host LOCAL' /proc/net/fib_trie 2>/dev/null \
  | grep -E '\|-- [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | grep -v 127. \
  | awk -F'|-- ' '{print $2}' \
  | head -1)
[ -n "$IP" ] && printf '%s' "$IP" > /data/cleanhome.bridge_ip
(setsid systemd-socket-activate -l 8765 -a --inetd /data/launcher-api-handler.sh >/tmp/api.log 2>&1 </dev/null &)
(setsid /data/firetv-home.sh >/tmp/home.log 2>&1 </dev/null &)
(setsid /data/firetv-home-logwatch.sh >/tmp/home-logwatch.log 2>&1 </dev/null &)
(setsid /data/firetv-booster.sh >/tmp/booster.log 2>&1 </dev/null &)
(setsid /data/cleanhome-supervisor.sh >/tmp/supervisor.log 2>&1 </dev/null &)
sleep 2
/data/launch-clean-home.sh >/dev/null 2>&1 || true
