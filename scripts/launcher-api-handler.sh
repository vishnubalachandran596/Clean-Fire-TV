#!/bin/sh
read -r line
request=$(echo "$line" | awk '{print $2}')
path=$(echo "$request" | cut -d'?' -f1)
query_string=$(echo "$request" | cut -d'?' -f2-)

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Original Appstore icon PNGs (m.media-amazon.com) — ads-system widget returns empty on-device.
icon_url_for_pkg() {
  case "$1" in
    asin_B00E5NH6YG) printf '%s' 'https://m.media-amazon.com/images/I/41B9xWJ9sjL.png' ;;
    asin_B019DCHDZK) printf '%s' 'https://m.media-amazon.com/images/I/51PBOOfS7uL.png' ;;
    asin_B01LXOU5PM) printf '%s' 'https://m.media-amazon.com/images/I/41Ms7xpOIIL.png' ;;
    asin_B075NTHVJW) printf '%s' 'https://m.media-amazon.com/images/I/715irEQPXzL.png' ;;
    com.acorn.tv) printf '%s' 'https://m.media-amazon.com/images/I/71TFYt8E7SL.png' ;;
    com.amazon.firetv.youtube) printf '%s' 'https://m.media-amazon.com/images/I/4195dyf+rFL.png' ;;
    com.amazon.frenchpress) printf '%s' 'https://m.media-amazon.com/images/I/51tgW+J2A9L.png' ;;
    com.amazon.music.kepler) printf '%s' 'https://m.media-amazon.com/images/I/715E2xCPg7L.png' ;;
    com.amcn.amcplus.androidtv) printf '%s' 'https://m.media-amazon.com/images/I/31fHXMNSIzL.png' ;;
    com.apple.atve.amazon.appletv) printf '%s' 'https://m.media-amazon.com/images/I/61jw9jE9EhL.png' ;;
    com.att.tv) printf '%s' 'https://m.media-amazon.com/images/I/61zMKfz9CFL.png' ;;
    com.cbssports.android) printf '%s' 'https://m.media-amazon.com/images/I/71pYFFfWAKL.png' ;;
    com.charter.spectrum.guide) printf '%s' 'https://m.media-amazon.com/images/I/518DS7Xj4aL.png' ;;
    com.cnn.mobile.android.phone) printf '%s' 'https://m.media-amazon.com/images/I/61B27jrDQoL.png' ;;
    com.crunchyroll.crunchyroid) printf '%s' 'https://m.media-amazon.com/images/I/41o03HyOYlL.png' ;;
    com.espn.score_center) printf '%s' 'https://m.media-amazon.com/images/I/21h-OE4-X7L.png' ;;
    com.fandango) printf '%s' 'https://m.media-amazon.com/images/I/311ovAXdg3L.png' ;;
    com.fubo.android) printf '%s' 'https://m.media-amazon.com/images/I/51PBOOfS7uL.png' ;;
    com.futuretoday.android.filmrise) printf '%s' 'https://m.media-amazon.com/images/I/31uEF4y+SFL.png' ;;
    com.gaia.android) printf '%s' 'https://m.media-amazon.com/images/I/61qZ+UauQJL.png' ;;
    com.google.android.youtube.tvunplugged) printf '%s' 'https://m.media-amazon.com/images/I/31rcquarKXL.png' ;;
    com.history.watch) printf '%s' 'https://m.media-amazon.com/images/I/41B9xWJ9sjL.png' ;;
    com.hulu.plus) printf '%s' 'https://m.media-amazon.com/images/I/71Qtshc+1fL.png' ;;
    com.kanopy.android) printf '%s' 'https://m.media-amazon.com/images/I/21sBznspESL.png' ;;
    com.nbaimd.gametime.nba2011) printf '%s' 'https://m.media-amazon.com/images/I/41DhFXIEG+L.png' ;;
    com.nbcsports.liveextra) printf '%s' 'https://m.media-amazon.com/images/I/41l-hccEEJL.png' ;;
    com.netflix.kepler) printf '%s' 'https://m.media-amazon.com/images/I/51LGj5--KsL.png' ;;
    com.nfl.fantasy.core.android) printf '%s' 'https://m.media-amazon.com/images/I/41Ms7xpOIIL.png' ;;
    com.nordvpn.android) printf '%s' 'https://m.media-amazon.com/images/I/31o0QB0R0sL.png' ;;
    com.onemainstream.sonyliv.android) printf '%s' 'https://m.media-amazon.com/images/I/61JxXK7hNDL.png' ;;
    com.peacocktv.peacockandroid) printf '%s' 'https://m.media-amazon.com/images/I/6195DIr62TL.png' ;;
    com.plexapp.android) printf '%s' 'https://m.media-amazon.com/images/I/21hopceMfJL.png' ;;
    com.roku.web.trc) printf '%s' 'https://m.media-amazon.com/images/I/51Jq539xxZL.png' ;;
    com.screencast) printf '%s' 'https://m.media-amazon.com/images/I/71dHNvDTD7L.png' ;;
    com.spotify.tv.android) printf '%s' 'https://m.media-amazon.com/images/I/31u0VlL6zEL.png' ;;
    com.suntv.sunnxt) printf '%s' 'https://m.media-amazon.com/images/I/61w5YbybBiL.png' ;;
    com.tubitv) printf '%s' 'https://m.media-amazon.com/images/I/715irEQPXzL.png' ;;
    com.turner.tbs.android.networkapp) printf '%s' 'https://m.media-amazon.com/images/I/71r6Sr1rCwL.png' ;;
    com.xfinity.cloudtvr.tenfoot) printf '%s' 'https://m.media-amazon.com/images/I/71xZE-u+ivL.png' ;;
    com.zee5.amazon) printf '%s' 'https://m.media-amazon.com/images/I/81d2i1ujZbL.png' ;;
    in.AajTak.headlines) printf '%s' 'https://m.media-amazon.com/images/I/71b-fSdQC0L.png' ;;
    in.startv.hotstar) printf '%s' 'https://m.media-amazon.com/images/I/51DCCI7HwbL.png' ;;
    org.videolan.vlc) printf '%s' 'https://m.media-amazon.com/images/I/41UPIHLXcwL.png' ;;
    tv.airtel.xstream.tvapp) printf '%s' 'https://m.media-amazon.com/images/I/71JqJwLEvUL.png' ;;
    tv.fawesome.android) printf '%s' 'https://m.media-amazon.com/images/I/616ts3012JL.png' ;;
    tv.pluto.android) printf '%s' 'https://m.media-amazon.com/images/I/41-BIhPLNdL.png' ;;
    *) printf '' ;;
  esac
}

asin_icon_url() {
  # Fallback only — prefer icon_url_for_pkg. Direct I/ URLs work; ads widget does not on stick.
  printf 'https://m.media-amazon.com/images/P/%s.01._SCLZZZZZZZ_SX512_.jpg' "$1"
}

# Append one dock app JSON object if package is installed (dedupe via SEEN_PKGS).
emit_app_if_installed() {
  pkg="$1"
  comp="$2"
  echo "$SEEN_PKGS" | grep -F "|${pkg}|" >/dev/null 2>&1 && return 0
  vpm info "$pkg" >/dev/null 2>&1 || return 0
  title=$(vpm info "$pkg" 2>/dev/null | awk -F': ' '/^[[:space:]]*value:/ {print $2; exit}')
  [ -z "$title" ] && title="$pkg"
  asin=$(vpm info "$pkg" 2>/dev/null | awk -F': ' '/store id:/ {print $2; exit}' | tr -d '[:space:]')
  [ -z "$asin" ] && asin=$(vpm info "$pkg" 2>/dev/null | awk -F'"' '/"asin"/ {print $4; exit}' | tr -d '[:space:]')
  icon=$(icon_url_for_pkg "$pkg")
  [ -z "$icon" ] && [ -n "$asin" ] && icon=$(asin_icon_url "$asin")
  [ "$first" -eq 0 ] && echo -n ','
  first=0
  SEEN_PKGS="${SEEN_PKGS}|${pkg}|"
  printf '{"packageId":"%s","component":"%s","title":"%s","asin":"%s","iconUrl":"%s"}' \
    "$(json_escape "$pkg")" "$(json_escape "$comp")" "$(json_escape "$title")" \
    "$(json_escape "$asin")" "$(json_escape "$icon")"
}

list_apps_json() {
  # All installed user apps with .main — media category alone misses Crunchyroll /
  # Xstream Play / Music (they often only appear under category.main).
  EXCLUDE='cleanhome|smplighthouse|vegaoobe|vegatvdevoptions|visualindicator|screensaver|captiveportal|turnstile|consentui|legalnotices|profilepicker|notification|iap\.core|kepler\.cp_settings|a11y_tutorial|vegaconversation|textbanner|landingpagebuilder|lvc\.|vegaepg|vegaeasyupgrade|tigris|wakeuphandler|ssm\.|ssmsys|dms\.ssi|sangam|devicecontrol|volume_panel|uri_resolver|kepler\.uri|amazon\.tahoe|venezia|cloud9|appstorevegatv|vegatvsettings|alexawebapi|networking\.speedtest|hdmi\.certificate|avsinkcap|otad|csapp|miracast|pcon\.tv|skillconnection|mm\.ffr|arol|ceviche|syrax|identity\.lwa|aplext|cloudstreaming|settings\.avsync|vegasettingslivetv|rdm\.service|firetv\.notification'

  echo -n '{"ok":true,"apps":['
  first=1
  SEEN_PKGS='|'

  for cat in com.amazon.category.kepler.media com.amazon.category.main; do
    for comp in $(vpm list components --category="$cat" 2>/dev/null | awk 'NR>1 {print $1}'); do
      echo "$comp" | grep -qiE "$EXCLUDE" && continue
      case "$comp" in *.main) ;; *) continue ;; esac
      pkg=$(echo "$comp" | sed 's/\.main$//')
      echo "$pkg" | grep -qiE "$EXCLUDE" && continue
      emit_app_if_installed "$pkg" "$comp"
    done
  done

  # Known packages — include if installed even when category miss.
  emit_app_if_installed com.crunchyroll.crunchyroid com.crunchyroll.crunchyroid.main
  emit_app_if_installed tv.airtel.xstream.tvapp tv.airtel.xstream.tvapp.main
  emit_app_if_installed com.amazon.music.kepler com.amazon.music.kepler.main
  emit_app_if_installed com.spotify.tv.android com.spotify.tv.android.main
  emit_app_if_installed com.plexapp.android com.plexapp.android.main
  emit_app_if_installed com.tubitv com.tubitv.main
  emit_app_if_installed tv.pluto.android tv.pluto.android.main
  emit_app_if_installed com.peacocktv.peacockandroid com.peacocktv.peacockandroid.main
  emit_app_if_installed com.hulu.plus com.hulu.plus.main
  emit_app_if_installed com.espn.score_center com.espn.score_center.main
  emit_app_if_installed com.google.android.youtube.tvunplugged com.google.android.youtube.tvunplugged.main
  emit_app_if_installed org.videolan.vlc org.videolan.vlc.main
  emit_app_if_installed com.nordvpn.android com.nordvpn.android.main
  emit_app_if_installed in.AajTak.headlines in.AajTak.headlines.main
  emit_app_if_installed com.fubo.android com.fubo.android.main
  emit_app_if_installed com.expressvpn.vpn com.expressvpn.vpn.main
  emit_app_if_installed com.surfshark.vpn.client com.surfshark.vpn.client.main
  emit_app_if_installed ch.protonvpn.android ch.protonvpn.android.main
  emit_app_if_installed com.privateinternetaccess.android com.privateinternetaccess.android.main
  emit_app_if_installed com.windscribe.vpn com.windscribe.vpn.main
  emit_app_if_installed com.mullvad.vpn com.mullvad.vpn.main
  emit_app_if_installed com.cyberghost.android.vpn com.cyberghost.android.vpn.main
  emit_app_if_installed com.hotspotshield.vpn.android com.hotspotshield.vpn.android.main
  emit_app_if_installed com.tunnelbear.android com.tunnelbear.android.main
  emit_app_if_installed net.openvpn.openvpn net.openvpn.openvpn.main
  emit_app_if_installed com.ivpn.client com.ivpn.client.main
  emit_app_if_installed org.jellyfin.androidtv org.jellyfin.androidtv.main
  emit_app_if_installed org.jellyfin.mobile org.jellyfin.mobile.main
  emit_app_if_installed com.embymedia.emby.tv com.embymedia.emby.tv.main
  emit_app_if_installed org.xbmc.kodi org.xbmc.kodi.main
  emit_app_if_installed com.disney.disneyplus com.disney.disneyplus.main
  emit_app_if_installed com.wbd.stream com.wbd.stream.main
  emit_app_if_installed com.cbs.ott com.cbs.ott.main
  emit_app_if_installed com.twitch.android.app com.twitch.android.app.main
  emit_app_if_installed com.sling com.sling.main
  emit_app_if_installed com.discovery.discoveryplus.mobile com.discovery.discoveryplus.mobile.main
  emit_app_if_installed com.amazon.imdb.tv.android.app com.amazon.imdb.tv.android.app.main
  emit_app_if_installed com.aftvnews.downloader com.aftvnews.downloader.main
  emit_app_if_installed com.britbox.us com.britbox.us.main
  emit_app_if_installed com.xumo.xumo com.xumo.xumo.main
  emit_app_if_installed com.philo.philo com.philo.philo.main
  emit_app_if_installed com.pbs.video com.pbs.video.main
  emit_app_if_installed com.byutv.android com.byutv.android.main
  emit_app_if_installed com.aenetworks.lifetime com.aenetworks.lifetime.main
  emit_app_if_installed com.mxtech.videoplayer.television com.mxtech.videoplayer.television.main
  emit_app_if_installed com.jio.media.ondemand com.jio.media.ondemand.main
  emit_app_if_installed com.tv.v18.viola com.tv.v18.viola.main
  emit_app_if_installed com.bsbportal.music com.bsbportal.music.main
  emit_app_if_installed com.cw.android.stream com.cw.android.stream.main
  emit_app_if_installed com.amc.tv com.amc.tv.main
  emit_app_if_installed com.starz.starzplay.android com.starz.starzplay.android.main
  emit_app_if_installed com.shudder.android com.shudder.android.main
  emit_app_if_installed com.mubi.androidtv com.mubi.androidtv.main
  emit_app_if_installed com.mgm.mgmplus com.mgm.mgmplus.main
  emit_app_if_installed com.fox.android.foxnow com.fox.android.foxnow.main
  emit_app_if_installed com.nbc.android.nbctve com.nbc.android.nbctve.main
  emit_app_if_installed com.abc.tv.android com.abc.tv.android.main
  emit_app_if_installed com.hallmarkmoviesnow com.hallmarkmoviesnow.main
  emit_app_if_installed com.redbox.android com.redbox.android.main
  emit_app_if_installed tv.pureflix.android tv.pureflix.android.main
  emit_app_if_installed com.futuretoday.android.filmrise com.futuretoday.android.filmrise.main
  emit_app_if_installed com.xfinity.cloudtvr.tenfoot com.xfinity.cloudtvr.tenfoot.main
  emit_app_if_installed com.att.tv com.att.tv.main
  emit_app_if_installed com.roku.web.trc com.roku.web.trc.main
  emit_app_if_installed com.kanopy.android com.kanopy.android.main
  emit_app_if_installed com.nfl.fantasy.core.android com.nfl.fantasy.core.android.main
  emit_app_if_installed com.cnn.mobile.android.phone com.cnn.mobile.android.phone.main
  emit_app_if_installed com.nbcsports.liveextra com.nbcsports.liveextra.main
  emit_app_if_installed com.nbaimd.gametime.nba2011 com.nbaimd.gametime.nba2011.main
  emit_app_if_installed com.fandango com.fandango.main
  emit_app_if_installed com.gaia.android com.gaia.android.main
  emit_app_if_installed com.cbssports.android com.cbssports.android.main
  emit_app_if_installed com.acorn.tv com.acorn.tv.main
  emit_app_if_installed com.charter.spectrum.guide com.charter.spectrum.guide.main
  emit_app_if_installed tv.fawesome.android tv.fawesome.android.main
  emit_app_if_installed com.history.watch com.history.watch.main
  emit_app_if_installed com.amcn.amcplus.androidtv com.amcn.amcplus.androidtv.main
  emit_app_if_installed com.turner.tbs.android.networkapp com.turner.tbs.android.networkapp.main
  emit_app_if_installed com.screencast com.screencast.main

  # Pinned Clean controls (always last).
  [ "$first" -eq 0 ] && echo -n ','
  printf '{"packageId":"com.cleanhome.launcher.settings","component":"com.cleanhome.launcher.settings","title":"Settings","asin":"","iconUrl":""}'
  echo -n ','
  printf '{"packageId":"com.amazon.smplighthouse.launcher","component":"com.amazon.smplighthouse.launcher.main","title":"FireTV","asin":"","iconUrl":""}'
  echo ']}'
}

start_booster_if_needed() {
  if ps -ef 2>/dev/null | grep -v grep | grep -q firetv-booster.sh; then
    return 0
  fi
  setsid /data/firetv-booster.sh >/tmp/booster.log 2>&1 </dev/null &
}

RETURN_CLEAN="/data/cleanhome.return_clean"
HOME_PRESSED_TS="/data/cleanhome.home_pressed_ts"

AMAZON_MODE_TS="/data/cleanhome.amazon_mode_ts"

leave_amazon_mode() {
  rm -f /data/cleanhome.amazon_mode "$AMAZON_MODE_TS"
  start_booster_if_needed
}

# Same outcome as boot supervisor: Amazon pause off, redirect + booster alive, no extra app launch.
resume_clean_default() {
  rm -f /data/cleanhome.amazon_mode "$AMAZON_MODE_TS"
  date +%s > "$HOME_PRESSED_TS"
  touch "$RETURN_CLEAN"
  start_booster_if_needed
  sh /data/ensure-services.sh --no-launch
  return_to_clean_home
}

foreground_clean_if_running() {
  CLEAN_PKG="com.cleanhome.launcher.main"
  line=$(vlcm list 2>/dev/null | grep "$CLEAN_PKG" | head -1)
  [ -z "$line" ] && return 1
  echo "$line" | grep -qw "VISIBLE" && return 0
  inst=$(echo "$line" | tr -s ' ' | cut -d' ' -f4)
  pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
  [ -z "$inst" ] || [ "$pid" = "0" ] && return 1
  vlcm trigger-app foreground --inst "$inst" >/dev/null 2>&1 \
    || vmsgr launch-app "pkg://$CLEAN_PKG" >/dev/null 2>&1
  return 0
}

signal_return_clean() {
  leave_amazon_mode
  date +%s > "$HOME_PRESSED_TS"
  touch "$RETURN_CLEAN"
}

return_to_clean_home() {
  signal_return_clean
  CLEAN_PKG="com.cleanhome.launcher.main"
  SMPL_PKG="com.amazon.smplighthouse.launcher"
  # Clear stuck IDLE (pid 0) placeholders that block real launches.
  line=$(vlcm list 2>/dev/null | grep "$CLEAN_PKG" | head -1)
  pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
  if [ -n "$line" ] && [ "$pid" = "0" ]; then
    vlcm terminate-app --pkg-id com.cleanhome.launcher --force >/dev/null 2>&1
  fi
  # Soft handoff — hard-kill smpl every iteration caused Clean↔smpl wakeOnCrash loops.
  date +%s > /data/cleanhome.leave_ts
  # Fire Clean first (no wait) so Home feels instant; then soft-background smpl.
  vmsgr send "pkg://$CLEAN_PKG" >/dev/null 2>&1 &
  smpl_line=$(vlcm list 2>/dev/null | grep "$SMPL_PKG.main" | head -1)
  if echo "$smpl_line" | grep -qw "VISIBLE"; then
    smpl_inst=$(echo "$smpl_line" | tr -s ' ' | cut -d' ' -f4)
    [ -n "$smpl_inst" ] && vlcm trigger-app background --inst "$smpl_inst" >/dev/null 2>&1
  fi
  i=0
  while [ "$i" -lt 4 ]; do
    i=$((i + 1))
    line=$(vlcm list 2>/dev/null | grep "$CLEAN_PKG" | head -1)
    if echo "$line" | grep -qw "VISIBLE"; then
      return 0
    fi
    pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
    inst=$(echo "$line" | tr -s ' ' | cut -d' ' -f4)
    if [ -n "$line" ] && [ "$pid" = "0" ]; then
      vlcm terminate-app --pkg-id com.cleanhome.launcher --force >/dev/null 2>&1
    fi
    vmsgr send "pkg://$CLEAN_PKG" >/dev/null 2>&1 \
      || vmsgr launch-app "pkg://$CLEAN_PKG" >/dev/null 2>&1 \
      || vlcm launch-app "pkg://$CLEAN_PKG" --singleton >/dev/null 2>&1
    line=$(vlcm list 2>/dev/null | grep "$CLEAN_PKG" | head -1)
    pid=$(echo "$line" | tr -s ' ' | cut -d' ' -f3)
    inst=$(echo "$line" | tr -s ' ' | cut -d' ' -f4)
    if [ -n "$inst" ] && [ -n "$pid" ] && [ "$pid" != "0" ]; then
      vlcm trigger-app foreground --inst "$inst" >/dev/null 2>&1
    fi
    sleep 0.12
  done
  return 0
}

pause_clean_redirect() {
  touch /data/cleanhome.amazon_mode
  date +%s > /data/cleanhome.amazon_mode_ts
  # Stale home-press / return markers must not immediately exit Amazon mode.
  rm -f /data/cleanhome.home_pressed_ts /data/cleanhome.return_clean
  # Keep screensaver killer; only streaming kills pause via amazon_mode check.
  if ! ps -ef 2>/dev/null | grep '[f]iretv-booster.sh' | grep -q .; then
    setsid /data/firetv-booster.sh >/tmp/booster.log 2>&1 </dev/null &
  fi
}

enter_amazon_home() {
  pause_clean_redirect
  CLEAN_PKG="com.cleanhome.launcher.main"
  SMPL="com.amazon.smplighthouse.launcher.main"
  # Keep Clean listed in background (no wait loops — inetd must return fast).
  if ! vlcm list 2>/dev/null | grep -q "$CLEAN_PKG"; then
    vmsgr launch-app "pkg://$CLEAN_PKG" >/dev/null 2>&1 \
      || vlcm launch-app "pkg://$CLEAN_PKG" --singleton >/dev/null 2>&1
  fi
  # One-shot open Amazon — do not poll VISIBLE here (that added ~3s delay).
  vmsgr send "pkg://$SMPL" >/dev/null 2>&1 \
    || vmsgr launch-app "pkg://$SMPL" >/dev/null 2>&1 \
    || vlcm launch-app "pkg://$SMPL" >/dev/null 2>&1
}

ensure_services() {
  if echo "$query_string" | grep -qE '(^|&)(noLaunch=1|no-launch=1)'; then
    sh /data/ensure-services.sh --no-launch
  else
    sh /data/ensure-services.sh
  fi
}

urldecode() {
  printf '%s' "$1" | sed 's/+/ /g; s/%20/ /g; s/%2B/+/g'
}

urldecode_query() {
  printf '%s' "$1" | awk '
  {
    s = $0
    while (match(s, /%[0-9A-Fa-f][0-9A-Fa-f]/)) {
      hex = substr(s, RSTART + 1, 2)
      cmd = sprintf("printf \"\\x%s\"", hex)
      cmd | getline ch
      close(cmd)
      s = substr(s, 1, RSTART - 1) ch substr(s, RSTART + 3)
    }
    gsub(/\+/, " ", s)
    print s
  }'
}

wifi_ssid_is_valid() {
  ssid="$1"
  [ -z "$ssid" ] && return 1
  echo "$ssid" | grep -qi 'unknown.*ssid' && return 1
  echo "$ssid" | grep -qi '^unknown network$' && return 1
  echo "$ssid" | grep -qi '^%3cunknown' && return 1
  case "$ssid" in
    Wi-Fi\ \(*|"<unknown"*) return 1 ;;
  esac
  return 0
}

wifi_ssid_sanitize_file() {
  if [ ! -f /data/cleanhome.ssid ]; then
    return 0
  fi
  raw=$(head -1 /data/cleanhome.ssid 2>/dev/null | tr -d '\r\n')
  decoded=$(urldecode_query "$raw")
  if wifi_ssid_is_valid "$decoded"; then
    [ "$decoded" != "$raw" ] && printf '%s' "$decoded" > /data/cleanhome.ssid
    return 0
  fi
  rm -f /data/cleanhome.ssid
}

local_ip_from_fib() {
  grep -B1 'host LOCAL' /proc/net/fib_trie 2>/dev/null \
    | grep -E '\|-- [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
    | grep -v 127. \
    | awk -F'|-- ' '{print $2}' \
    | head -1
}

# Publish LAN IP for the RN app (loopback fetch often fails in the sandbox).
publish_bridge_ip() {
  ip_addr=$(local_ip_from_fib)
  if [ -n "$ip_addr" ]; then
    printf '%s' "$ip_addr" > /data/cleanhome.bridge_ip
  fi
}

wifi_signal_bars() {
  link=$(awk '/wlan0:/ {gsub(/\./, "", $3); print $3; exit}' /proc/net/wireless 2>/dev/null)
  level=$(awk '/wlan0:/ {gsub(/\./, "", $4); print $4; exit}' /proc/net/wireless 2>/dev/null)
  dbm=-999
  if [ -n "$link" ] && [ "$link" -gt 0 ] 2>/dev/null; then
    if [ "$link" -ge 70 ]; then
      dbm=-45
    elif [ "$link" -ge 50 ]; then
      dbm=-55
    elif [ "$link" -ge 35 ]; then
      dbm=-65
    elif [ "$link" -ge 20 ]; then
      dbm=-75
    else
      dbm=-85
    fi
  elif [ -n "$level" ] && [ "$level" -gt 0 ] 2>/dev/null; then
    if [ "$level" -gt 128 ] 2>/dev/null; then
      dbm=$((level - 256))
    elif [ "$level" -le 100 ] 2>/dev/null; then
      dbm=$((0 - level))
    fi
  fi
  signal_bars=0
  signal_label="No signal"
  if [ "$dbm" -ge -50 ] 2>/dev/null; then
    signal_bars=4
    signal_label="Excellent"
  elif [ "$dbm" -ge -60 ] 2>/dev/null; then
    signal_bars=3
    signal_label="Good"
  elif [ "$dbm" -ge -70 ] 2>/dev/null; then
    signal_bars=2
    signal_label="Fair"
  elif [ "$dbm" -ge -80 ] 2>/dev/null; then
    signal_bars=1
    signal_label="Weak"
  fi
}

media_app_visible() {
  RUNNING=$(vlcm list 2>/dev/null)
  echo "$RUNNING" | grep -w 'VISIBLE' | grep -qiE \
    'netflix|youtube|hotstar|frenchpress|crunchyroll|appletv|zee5|sonyliv|sunnxt|xstream|prime' \
    && return 0
  return 1
}

read_cached_speed_mbps() {
  if [ -f /data/cleanhome.speed_mbps ]; then
    head -1 /data/cleanhome.speed_mbps 2>/dev/null
    return 0
  fi
  echo "0"
}

# Live wlan throughput via /proc/net/dev (seconds only — avoid 32-bit ms overflow).
# Returns live Mbps when traffic is flowing; otherwise last good cache (never sticky 0).
sample_live_speed_mbps() {
  now_s=$(date +%s | tr -cd '0-9')
  read -r iface rx tx <<EOF
$(awk '
  NR > 2 {
    iface=$1; gsub(":", "", iface);
    if (iface == "lo") next;
    rx=$2+0; tx=$10+0;
    if (iface == "wlan0") { print iface, rx, tx; exit }
    if (rx+tx > best) { best=rx+tx; bi=iface; br=rx; bt=tx }
  }
  END { if (bi != "") print bi, br, bt }
' /proc/net/dev)
EOF
  if [ -z "$iface" ] || [ -z "$rx" ]; then
    read_cached_speed_mbps
    return 0
  fi
  prev_line=$(cat /data/cleanhome.net_sample 2>/dev/null)
  prev_iface=$(echo "$prev_line" | awk '{print $1}')
  prev_rx=$(echo "$prev_line" | awk '{print $2}')
  prev_tx=$(echo "$prev_line" | awk '{print $3}')
  prev_s=$(echo "$prev_line" | awk '{print $4}')
  echo "$iface $rx $tx $now_s" > /data/cleanhome.net_sample

  live="0.00"
  if [ "$iface" = "$prev_iface" ] && [ -n "$prev_rx" ] && [ -n "$prev_s" ]; then
    dt=$((now_s - prev_s))
    if [ "$dt" -ge 1 ] && [ "$dt" -le 10 ]; then
      drx=$((rx - prev_rx))
      dtx=$((tx - prev_tx))
      [ "$drx" -lt 0 ] && drx=0
      [ "$dtx" -lt 0 ] && dtx=0
      bytes=$drx
      [ "$bytes" -eq 0 ] && bytes=$((drx + dtx))
      live=$(awk -v b="$bytes" -v t="$dt" 'BEGIN {
        if (t <= 0) { print "0.00"; exit }
        printf "%.2f", (b * 8) / t / 1000000
      }')
    fi
  fi

  # Prefer live when meaningful; else last good cache so HUD does not sit at 0.00.
  # (Cloudflare measure stays on /speed-test only — never from the 1s metrics path.)
  cached=$(read_cached_speed_mbps)
  case "$live" in
    ''|0|0.0|0.00)
      echo "${cached:-0.00}"
      ;;
    *)
      echo "$live" > /data/cleanhome.speed_mbps
      echo "$now_s" > /data/cleanhome.speed_ts
      echo "$live"
      ;;
  esac
}

measure_speed_mbps() {
  now=$(date +%s)
  force=0
  [ "$1" = "force" ] && force=1
  if [ "$force" -eq 0 ] && [ -f /data/cleanhome.speed_ts ] && [ -f /data/cleanhome.speed_mbps ]; then
    last=$(head -1 /data/cleanhome.speed_ts 2>/dev/null | tr -cd '0-9')
    if [ -n "$last" ] && [ $((now - last)) -lt 120 ] 2>/dev/null; then
      head -1 /data/cleanhome.speed_mbps 2>/dev/null
      return 0
    fi
  fi
  tmp=/data/cleanhome.speed.tmp
  stats=$(curl -s -o "$tmp" -w '%{size_download} %{time_total}' --max-time 22 \
    'https://speed.cloudflare.com/__down?bytes=3000000' 2>/dev/null)
  size=$(echo "$stats" | awk '{print $1}')
  elapsed=$(echo "$stats" | awk '{print $2}')
  rm -f "$tmp"
  mbps=0
  if [ -n "$size" ] && [ -n "$elapsed" ]; then
    mbps=$(awk -v b="$size" -v t="$elapsed" 'BEGIN {
      if (t <= 0) { print "0.00"; exit }
      printf "%.2f", (b * 8) / t / 1000000
    }')
  fi
  [ -z "$mbps" ] && mbps=0.00
  echo "$mbps" > /data/cleanhome.speed_mbps
  echo "$now" > /data/cleanhome.speed_ts
  echo "$mbps"
}

wifi_link_up() {
  ip_addr=$(local_ip_from_fib)
  [ -n "$ip_addr" ] && return 0
  return 1
}

resolve_wifi_ssid() {
  wifi_ssid_sanitize_file
  ssid=""
  wifi_link_up || return 0
  if [ -f /data/cleanhome.ssid ]; then
    ssid=$(head -1 /data/cleanhome.ssid 2>/dev/null | tr -d '\r\n')
    ssid=$(urldecode_query "$ssid")
  fi
  wifi_ssid_is_valid "$ssid" || ssid=""
}

bt_name_is_skipped() {
  case "$1" in
    inputd-*|*inputmgr*|*hdmipower*|*injection*) return 0 ;;
    WOW_INPUT_DEVICE|WOBLE_INPUT_DEVICE) return 0 ;;
    AVRCP|avrcp) return 0 ;;
    "" ) return 0 ;;
  esac
  return 1
}

bt_friendly_label() {
  case "$1" in
    "Amazon Fire TV Remote") printf '%s' "Fire TV Remote" ;;
    *) printf '%s' "$1" ;;
  esac
}

bt_audio_name_connected() {
  BT_AUDIO="/data/cleanhome.bt_audio_name"
  [ ! -f "$BT_AUDIO" ] && return 0
  name=$(head -1 "$BT_AUDIO" 2>/dev/null | tr -d '\r\n')
  bt_name_is_skipped "$name" && return 0
  case "$name" in
    "Bluetooth audio"|"bluetooth audio") return 0 ;;
  esac
  bt_friendly_label "$name"
}

ICON_ORDER_FILE="/data/cleanhome.icon_order.json"

read_dock_order_body() {
  order='[]'
  if [ -f "$ICON_ORDER_FILE" ]; then
    raw=$(head -c 8192 "$ICON_ORDER_FILE" 2>/dev/null | tr -d '\r\n')
    case "$raw" in
      \[*) order="$raw" ;;
    esac
  fi
  printf '{"ok":true,"order":%s}' "$order"
}

save_dock_order_from_query() {
  raw=$(echo "$query_string" | sed -n 's/.*[?&]order=\([^&]*\).*/\1/p')
  [ -z "$raw" ] && raw=$(echo "$query_string" | sed 's/^order=//; s/&.*//')
  decoded=$(urldecode_query "$raw")
  case "$decoded" in
    \[*) ;;
    *) decoded='[]' ;;
  esac
  len=$(printf '%s' "$decoded" | wc -c | tr -cd '0-9')
  if [ -z "$len" ] || [ "$len" -gt 8192 ] 2>/dev/null; then
    decoded='[]'
  fi
  printf '%s' "$decoded" > "$ICON_ORDER_FILE"
}

bt_cached_device_lines() {
  BT_LIST="/data/cleanhome.bt_devices"
  [ ! -f "$BT_LIST" ] && return 0
  while read -r name; do
    name=$(echo "$name" | tr -d '\r\n')
    [ -z "$name" ] && continue
    bt_name_is_skipped "$name" && continue
    label=$(bt_friendly_label "$name")
    [ -z "$label" ] && continue
    printf '%s\n' "$label"
  done < "$BT_LIST"
}

bluetooth_device_lines() {
  awk '
  BEGIN { bus=""; name="" }
  /^I:/ {
    bus=""
    for (i = 2; i <= NF; i++) {
      split($i, kv, "=")
      if (kv[1] == "Bus") bus = kv[2]
    }
  }
  /^N: Name="/ {
    name = $0
    sub(/^N: Name="/, "", name)
    sub(/"$/, "", name)
  }
  /^H:/ {
    if (bus == "0005" && name != "" && name != "AVRCP" &&
        name !~ /^inputd-/ && name !~ /inputmgr/ && name !~ /injection/ &&
        name != "WOW_INPUT_DEVICE" && name != "WOBLE_INPUT_DEVICE") {
      label = name
      if (name == "Amazon Fire TV Remote") label = "Fire TV Remote"
      key = tolower(label)
      if (!(key in seen)) {
        seen[key] = 1
        print label
      }
    }
    name = ""
  }
  ' /proc/bus/input/devices 2>/dev/null

  if awk -F'"' '/^N: Name="AVRCP"/ {found=1} END {exit !found}' /proc/bus/input/devices 2>/dev/null; then
    audio_name=$(bt_audio_name_connected)
    [ -n "$audio_name" ] && printf '%s\n' "$audio_name"
  fi

  bt_cached_device_lines
}

bluetooth_devices_json() {
  bt_tmp="/tmp/cleanhome-bt.$$"
  bt_dedup="/tmp/cleanhome-bt-dedup.$$"
  : > "$bt_tmp"
  bluetooth_device_lines >> "$bt_tmp"

  awk 'NF && !seen[tolower($0)]++' "$bt_tmp" > "$bt_dedup"

  echo -n '"bluetoothDevices":['
  first=1
  while read -r label; do
    [ -z "$label" ] && continue
    bt_name_is_skipped "$label" && continue
    label=$(bt_friendly_label "$label")
    [ "$first" -eq 0 ] && echo -n ','
    first=0
    printf '"%s"' "$(json_escape "$label")"
  done < "$bt_dedup"
  rm -f "$bt_tmp" "$bt_dedup"
  echo -n ']'
}

bluetooth_status() {
  bt_enabled=1
  bt_connected=0
  bt_label="Ready"
  bt_device=""
  first_line=$(bluetooth_device_lines | head -1)
  if [ -n "$first_line" ]; then
    bt_device="$first_line"
    bt_connected=1
  elif awk -F'"' '/^N: Name=/ {print $2}' /proc/bus/input/devices 2>/dev/null | grep -qiE 'woble|wow|remote'; then
    bt_device="Fire TV Remote"
    bt_connected=1
  else
    bt_device="—"
    bt_label="None"
    bt_connected=0
  fi
}

open_connectivity_hud() {
  ok=0
  if vmsgr launch-app "pkg://com.amazon.vegatvsettings.hud" >/dev/null 2>&1; then
    ok=1
  elif vlcm launch-app "pkg://com.amazon.vegatvsettings.hud" >/dev/null 2>&1; then
    ok=1
  fi
  return "$ok"
}

enter_network_panel() {
  # Network HUD only — do NOT set amazon_mode (that flag is for Amazon Home).
  date +%s > /data/cleanhome.launch_cooldown
  open_connectivity_hud
}

network_json() {
  ssid=""
  status="Offline"
  signal_bars=0
  signal_label="No signal"
  online=0
  latency_ms=0
  ip_addr=$(local_ip_from_fib)

  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    online=1
    status="Connected"
    latency_ms=$(ping -c 1 -W 2 8.8.8.8 2>/dev/null | awk '/round-trip/ {split($4,a,"/"); print int(a[2]+0.5); exit}')
  elif ping -c 1 -W 2 "$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')" >/dev/null 2>&1; then
    online=1
    status="LAN"
  elif [ -n "$ip_addr" ]; then
    online=1
    status="Local"
  fi

  wifi_signal_bars

  resolve_wifi_ssid
  [ -z "$ssid" ] && ssid=""

  if [ "$online" -eq 0 ]; then
    status="Offline"
  fi

  bluetooth_status

  printf '{"ok":true,"ssid":"%s","status":"%s","online":%s,"signalBars":%s,"signalLabel":"%s","latencyMs":%s,"ip":"%s","bluetoothEnabled":%s,"bluetoothConnected":%s,"bluetoothLabel":"%s","bluetoothDevice":"%s"}' \
    "$(json_escape "$ssid")" "$(json_escape "$status")" "$online" "$signal_bars" \
    "$(json_escape "$signal_label")" "${latency_ms:-0}" "$(json_escape "$ip_addr")" \
    "$bt_enabled" "$bt_connected" "$(json_escape "$bt_label")" "$(json_escape "$bt_device")"
}

screen_stats_json() {
  ssid=""
  status="Offline"
  online=0
  latency_ms=0
  ip_addr=$(local_ip_from_fib)
  signal_bars=0
  signal_label="No signal"

  if [ -f /data/cleanhome.latency_ms ]; then
    latency_ms=$(head -1 /data/cleanhome.latency_ms 2>/dev/null | tr -cd '0-9')
  fi
  if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
    online=1
    status="Connected"
    latency_ms=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null | awk '/round-trip/ {split($4,a,"/"); print int(a[2]+0.5); exit}')
    [ -n "$latency_ms" ] && echo "$latency_ms" > /data/cleanhome.latency_ms
  elif gw=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}') && [ -n "$gw" ] && ping -c 1 -W 1 "$gw" >/dev/null 2>&1; then
    online=1
    status="LAN"
  elif [ -n "$ip_addr" ]; then
    online=1
    status="Local"
  fi

  wifi_signal_bars
  resolve_wifi_ssid
  [ -z "$ssid" ] && ssid=""
  [ "$online" -eq 0 ] && status="Offline"

  bluetooth_status
  speed_mbps=$(read_cached_speed_mbps)
  bt_list=$(bluetooth_devices_json)
  ram_avail_mb=$(free -m | awk '/^Mem:/ {print $7}')
  ram_total_mb=$(free -m | awk '/^Mem:/ {print $2}')
  storage_total_mb=$(df -m /data 2>/dev/null | awk 'NR==2 {print $2}')
  storage_used_mb=$(df -m /data 2>/dev/null | awk 'NR==2 {print $3}')
  storage_free_mb=$(df -m /data 2>/dev/null | awk 'NR==2 {print $4}')
  amazon_mode=false
  [ -f /data/cleanhome.amazon_mode ] && amazon_mode=true
  booster_running=false
  ps -ef | grep -v grep | grep -q firetv-booster.sh && booster_running=true

  printf '{"ok":true,"ssid":"%s","status":"%s","online":%s,"signalBars":%s,"signalLabel":"%s","latencyMs":%s,"ip":"%s","speedMbps":%s,"bluetoothEnabled":%s,"bluetoothConnected":%s,"bluetoothLabel":"%s","bluetoothDevice":"%s",%s,"freeMb":%s,"totalMb":%s,"storageFreeMb":%s,"storageUsedMb":%s,"storageTotalMb":%s,"amazonMode":%s,"boosterRunning":%s}' \
    "$(json_escape "$ssid")" "$(json_escape "$status")" "$online" "$signal_bars" \
    "$(json_escape "$signal_label")" "${latency_ms:-0}" "$(json_escape "$ip_addr")" "${speed_mbps:-0}" \
    "$bt_enabled" "$bt_connected" "$(json_escape "$bt_label")" "$(json_escape "$bt_device")" "$bt_list" \
    "${ram_avail_mb:-0}" "${ram_total_mb:-0}" "${storage_free_mb:-0}" "${storage_used_mb:-0}" "${storage_total_mb:-0}" \
    "$amazon_mode" "$booster_running"
}

case "$path" in
  /apps*)
    body=$(list_apps_json)
    ;;
  /amazon-home*)
    date +%s > /data/cleanhome.launch_cooldown
    enter_amazon_home
    publish_bridge_ip
    ip_addr=$(local_ip_from_fib)
    body="{\"ok\":true,\"amazonHome\":true,\"amazonMode\":true,\"ip\":\"$(json_escape "$ip_addr")\"}"
    ;;
  /start-services*)
    ensure_services
    body='{"ok":true,"services":true}'
    ;;
  /clear-amazon-mode*)
    leave_amazon_mode
    body='{"ok":true,"amazonMode":false}'
    ;;
  /resume-default*|/stay-clean*)
    resume_clean_default
    displayManagerPm set active >/dev/null 2>&1
    body='{"ok":true,"cleanHome":true,"amazonMode":false,"resume":true}'
    ;;
  /keep-awake*)
    # Best-effort: keep panel active while Clean Home is focused (no OS sleep timer API for 3P).
    displayManagerPm set active >/dev/null 2>&1
    body='{"ok":true,"keepAwake":true}'
    ;;
  /home-to-clean*)
    return_to_clean_home
    sh /data/ensure-services.sh
    displayManagerPm set active >/dev/null 2>&1
    body='{"ok":true,"cleanHome":true}'
    ;;
  /search*)
    raw=$(echo "$query_string" | sed 's/^q=//')
    q=$(urldecode "$raw")
    if [ -n "$q" ]; then
      enc=$(printf '%s' "$q" | sed 's/ /+/g')
      vlcm launch-app "amzns://apps?search=$enc" >/dev/null 2>&1 \
        || vmsgr send "amzns://apps?search=$enc" >/dev/null 2>&1 \
        || vlcm launch-app "pkg://com.amazon.smplighthouse.launcher.searchInput" >/dev/null 2>&1
    else
      vlcm launch-app "pkg://com.amazon.smplighthouse.launcher.searchInput" >/dev/null 2>&1 \
        || vmsgr send "pkg://com.amazon.smplighthouse.launcher.searchInput" >/dev/null 2>&1
    fi
    body="{\"ok\":true,\"search\":true,\"query\":\"$(json_escape "$q")\"}"
    ;;
  /launch/*)
    target=$(echo "$path" | sed "s|^/launch/||" | sed 's/%2F/\//g' | sed 's/%2E/./g')
    uri="pkg://$target"
    ok=0
    # Give the target time to go VISIBLE before booster cleans background apps.
    date +%s > /data/cleanhome.launch_cooldown
    case "$target" in
      com.cleanhome.launcher|com.cleanhome.launcher.main*)
        resume_clean_default
        line=$(vlcm list 2>/dev/null | grep "com.cleanhome.launcher.main" | head -1)
        if [ -z "$line" ] || ! echo "$line" | grep -qw "VISIBLE"; then
          return_to_clean_home
        fi
        ok=1
        ;;
      com.amazon.vegatvsettings.main|com.amazon.vegatvsettings.hud|com.amazon.appstorevegatv.main|com.amazon.vegatvdevoptionsapp.main|com.amazon.kepler.cp_settings_ui.main|com.amazon.vegatvlegalnotices.main|com.amazon.vegatvconsentui.main|com.amazon.vegatvsettings.ratings.main|com.amazon.vegaeasyupgrade.main|com.amazon.notification.renderer.ui)
        if vmsgr launch-app "$uri" >/dev/null 2>&1; then
          ok=1
        elif vlcm launch-app "$uri" >/dev/null 2>&1; then
          ok=1
        fi
        ;;
      *)
        # vmsgr send is more reliable for VISIBLE than launch-app alone.
        if vmsgr send "$uri" >/dev/null 2>&1; then
          ok=1
        elif vmsgr launch-app "$uri" >/dev/null 2>&1; then
          ok=1
        elif vlcm launch-app "$uri" >/dev/null 2>&1; then
          ok=1
        fi
        ;;
    esac
    body="{\"ok\":$([ "$ok" -eq 1 ] && echo true || echo false),\"launched\":\"$target\"}"
    ;;
  /home*)
    if [ -f /data/cleanhome.amazon_mode ]; then
      return_to_clean_home
      body='{"ok":true,"home":true,"cleanHome":true}'
    else
    # Do not kill Appstore, Settings, or Amazon Home (breaks stock launcher + store).
    for pkg in \
      com.amazon.screensaver \
      com.netflix.kepler \
      com.apple.atve.amazon.appletv \
      com.suntv.sunnxt \
      com.zee5.amazon \
      com.onemainstream.sonyliv.android \
      in.startv.hotstar \
      tv.airtel.xstream.tvapp \
      com.crunchyroll.crunchyroid \
      com.amazon.frenchpress \
      com.amazon.firetv.youtube \
      com.amazon.tahoe
    do
      vlcm terminate-app --pkg-id "$pkg" --force >/dev/null 2>&1
    done
    free_mb=$(free -m | awk "/^Mem:/ {print \$7}")
    body="{\"ok\":true,\"home\":true,\"freeMb\":$free_mb}"
    fi
    ;;
  /screensaver-kill*)
    vlcm terminate-app --pkg-id com.amazon.screensaver --force >/dev/null 2>&1
    body='{"ok":true,"screensaver":false}'
    ;;
  /network-panel*|/wifi-setup*|/bluetooth-setup*)
    enter_network_panel
    body='{"ok":true,"hud":true,"amazonMode":false}'
    ;;
  /dock-order*)
    if echo "$query_string" | grep -q 'order='; then
      save_dock_order_from_query
      body='{"ok":true,"saved":true}'
    else
      body=$(read_dock_order_body)
    fi
    ;;
  /cache-ssid*)
    raw=$(echo "$query_string" | sed 's/^ssid=//; s/&.*//')
    cached=$(urldecode_query "$raw")
    if wifi_ssid_is_valid "$cached"; then
      printf '%s' "$cached" > /data/cleanhome.ssid
    else
      rm -f /data/cleanhome.ssid
      cached=""
    fi
    body="{\"ok\":true,\"ssid\":\"$(json_escape "$cached")\"}"
    ;;
  /cache-bt-devices*)
    names_raw=$(echo "$query_string" | sed -n 's/.*[?&]names=\([^&]*\).*/\1/p')
    [ -z "$names_raw" ] && names_raw=$(echo "$query_string" | sed 's/^names=//; s/&.*//')
    decoded=$(urldecode_query "$names_raw")
    BT_LIST="/data/cleanhome.bt_devices"
    : > "$BT_LIST"
    printf '%s\n' "$decoded" | while read -r name; do
      name=$(echo "$name" | tr -d '\r')
      [ -z "$name" ] && continue
      bt_name_is_skipped "$name" && continue
      label=$(bt_friendly_label "$name")
      [ -z "$label" ] && continue
      printf '%s\n' "$label" >> "$BT_LIST"
    done
    count=0
    if [ -s "$BT_LIST" ]; then
      count=$(wc -l < "$BT_LIST" | tr -cd '0-9')
    else
      rm -f "$BT_LIST"
    fi
    body="{\"ok\":true,\"count\":$count}"
    ;;
  /cache-bt-device*)
    label=""
    name_raw=$(echo "$query_string" | sed -n 's/.*[?&]name=\([^&]*\).*/\1/p')
    [ -z "$name_raw" ] && name_raw=$(echo "$query_string" | sed 's/^name=//; s/&.*//')
    name=$(urldecode_query "$name_raw")
    name=$(echo "$name" | tr -d '\r\n')
    is_audio=0
    echo "$query_string" | grep -q 'audio=1' && is_audio=1
    if [ -n "$name" ] && ! bt_name_is_skipped "$name"; then
      label=$(bt_friendly_label "$name")
      case "$label" in
        "Bluetooth audio"|"bluetooth audio") label="" ;;
      esac
      if [ -n "$label" ] && [ "$is_audio" -eq 1 ]; then
        printf '%s' "$label" > /data/cleanhome.bt_audio_name
      fi
    fi
    body="{\"ok\":true,\"name\":\"$(json_escape "$label")\"}"
    ;;
  /speed-test*|/refresh-speed*)
    if media_app_visible; then
      speed_mbps=$(read_cached_speed_mbps)
      body="{\"ok\":true,\"speedMbps\":$speed_mbps,\"skipped\":true}"
    else
      speed_mbps=$(measure_speed_mbps force)
      body="{\"ok\":true,\"speedMbps\":$speed_mbps,\"skipped\":false}"
    fi
    ;;
  /screen-stats-fast*)
    # No ping / BT scan / Cloudflare — keeps the inetd bridge free for /launch.
    # Speed = live wlan byte-delta Mbps (updates every ~1s with UI poll).
    publish_bridge_ip
    ip_addr=$(local_ip_from_fib)
    speed_mbps=$(sample_live_speed_mbps)
    ram_avail_mb=$(free -m | awk '/^Mem:/ {print $7}')
    ram_total_mb=$(free -m | awk '/^Mem:/ {print $2}')
    storage_total_mb=$(df -m /data 2>/dev/null | awk 'NR==2 {print $2}')
    storage_used_mb=$(df -m /data 2>/dev/null | awk 'NR==2 {print $3}')
    storage_free_mb=$(df -m /data 2>/dev/null | awk 'NR==2 {print $4}')
    body="{\"ok\":true,\"freeMb\":${ram_avail_mb:-0},\"totalMb\":${ram_total_mb:-0},\"storageFreeMb\":${storage_free_mb:-0},\"storageUsedMb\":${storage_used_mb:-0},\"storageTotalMb\":${storage_total_mb:-0},\"speedMbps\":${speed_mbps:-0},\"ip\":\"$(json_escape "$ip_addr")\"}"
    ;;
  /screen-stats*)
    publish_bridge_ip
    body=$(screen_stats_json)
    ;;
  /status*)
    publish_bridge_ip
    free_mb=$(free -m | awk "/^Mem:/ {print \$7}")
    total_mb=$(free -m | awk "/^Mem:/ {print \$2}")
    amazon_mode=false
    [ -f /data/cleanhome.amazon_mode ] && amazon_mode=true
    booster_running=false
    ps -ef | grep -v grep | grep -q firetv-booster.sh && booster_running=true
    ip_addr=$(local_ip_from_fib)
    body="{\"ok\":true,\"freeMb\":$free_mb,\"totalMb\":$total_mb,\"amazonMode\":$amazon_mode,\"boosterRunning\":$booster_running,\"ip\":\"$(json_escape "$ip_addr")\"}"
    ;;
  /network*)
    body=$(network_json)
    ;;
  *)
    body="{\"ok\":true}"
    ;;
esac
body=$(printf '%s' "$body" | tr -d '\n')
body_len=$(printf '%s' "$body" | wc -c | tr -d ' ')
printf 'HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: application/json\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "$body_len" "$body"
