# Bundled dock icon catalog

This repo ships **88** bundled app icons for the Clean Home dock (rectangular tiles with artwork skewed via `resizeMode="stretch"` — fills the tile, no crop).

Icons live under `assets/icons/<packageId>.png`, are wired in `BUNDLED_ICONS` (`src/App.tsx`), and are listed for live `/apps` in `icon_url_for_pkg` when an Appstore CDN URL is known (`scripts/launcher-api-handler.sh`, `assets/icons/asin_icon_urls.json`).

The dock still only shows apps **installed on the stick** — these files are offline artwork so tiles look correct even when CDN fetch fails.

| Count | Group |
|------:|-------|
| 5 | Media server / player |
| 71 | Streaming / TV |
| 12 | VPN |
| **88** | **Total** |

## Full list

| Category | App | Package ID | File |
|----------|-----|------------|------|
| Media server / player | Emby | `com.embymedia.emby.tv` | `assets/icons/com.embymedia.emby.tv.png` |
| Media server / player | Jellyfin | `org.jellyfin.androidtv` | `assets/icons/org.jellyfin.androidtv.png` |
| Media server / player | Jellyfin (Mobile) | `org.jellyfin.mobile` | `assets/icons/org.jellyfin.mobile.png` |
| Media server / player | Kodi | `org.xbmc.kodi` | `assets/icons/org.xbmc.kodi.png` |
| Media server / player | Plex | `com.plexapp.android` | `assets/icons/com.plexapp.android.png` |
| Streaming / TV | Aaj Tak | `in.AajTak.headlines` | `assets/icons/in.AajTak.headlines.png` |
| Streaming / TV | ABC | `com.abc.tv.android` | `assets/icons/com.abc.tv.android.png` |
| Streaming / TV | Acorn TV | `com.acorn.tv` | `assets/icons/com.acorn.tv.png` |
| Streaming / TV | Amazon Music | `com.amazon.music.kepler` | `assets/icons/com.amazon.music.kepler.png` |
| Streaming / TV | AMC | `com.amc.tv` | `assets/icons/com.amc.tv.png` |
| Streaming / TV | AMC+ | `com.amcn.amcplus.androidtv` | `assets/icons/com.amcn.amcplus.androidtv.png` |
| Streaming / TV | Apple TV | `com.apple.atve.amazon.appletv` | `assets/icons/com.apple.atve.amazon.appletv.png` |
| Streaming / TV | BritBox | `com.britbox.us` | `assets/icons/com.britbox.us.png` |
| Streaming / TV | BYUtv | `com.byutv.android` | `assets/icons/com.byutv.android.png` |
| Streaming / TV | CBS Sports | `com.cbssports.android` | `assets/icons/com.cbssports.android.png` |
| Streaming / TV | CNN | `com.cnn.mobile.android.phone` | `assets/icons/com.cnn.mobile.android.phone.png` |
| Streaming / TV | Crunchyroll | `com.crunchyroll.crunchyroid` | `assets/icons/com.crunchyroll.crunchyroid.png` |
| Streaming / TV | DIRECTV | `com.att.tv` | `assets/icons/com.att.tv.png` |
| Streaming / TV | discovery+ | `com.discovery.discoveryplus.mobile` | `assets/icons/com.discovery.discoveryplus.mobile.png` |
| Streaming / TV | Disney+ | `com.disney.disneyplus` | `assets/icons/com.disney.disneyplus.png` |
| Streaming / TV | Downloader | `com.aftvnews.downloader` | `assets/icons/com.aftvnews.downloader.png` |
| Streaming / TV | ESPN | `com.espn.score_center` | `assets/icons/com.espn.score_center.png` |
| Streaming / TV | Fandango | `com.fandango` | `assets/icons/com.fandango.png` |
| Streaming / TV | Fawesome | `tv.fawesome.android` | `assets/icons/tv.fawesome.android.png` |
| Streaming / TV | FilmRise | `com.futuretoday.android.filmrise` | `assets/icons/com.futuretoday.android.filmrise.png` |
| Streaming / TV | FOX NOW | `com.fox.android.foxnow` | `assets/icons/com.fox.android.foxnow.png` |
| Streaming / TV | Freevee | `com.amazon.imdb.tv.android.app` | `assets/icons/com.amazon.imdb.tv.android.app.png` |
| Streaming / TV | Fubo | `com.fubo.android` | `assets/icons/com.fubo.android.png` |
| Streaming / TV | Gaia | `com.gaia.android` | `assets/icons/com.gaia.android.png` |
| Streaming / TV | Hallmark Movies Now | `com.hallmarkmoviesnow` | `assets/icons/com.hallmarkmoviesnow.png` |
| Streaming / TV | HISTORY | `com.history.watch` | `assets/icons/com.history.watch.png` |
| Streaming / TV | Hulu | `com.hulu.plus` | `assets/icons/com.hulu.plus.png` |
| Streaming / TV | Hungama Play | `com.bsbportal.music` | `assets/icons/com.bsbportal.music.png` |
| Streaming / TV | Jio Hotstar | `in.startv.hotstar` | `assets/icons/in.startv.hotstar.png` |
| Streaming / TV | JioCinema | `com.jio.media.ondemand` | `assets/icons/com.jio.media.ondemand.png` |
| Streaming / TV | Kanopy | `com.kanopy.android` | `assets/icons/com.kanopy.android.png` |
| Streaming / TV | Lifetime | `com.aenetworks.lifetime` | `assets/icons/com.aenetworks.lifetime.png` |
| Streaming / TV | Max | `com.wbd.stream` | `assets/icons/com.wbd.stream.png` |
| Streaming / TV | MGM+ | `com.mgm.mgmplus` | `assets/icons/com.mgm.mgmplus.png` |
| Streaming / TV | MUBI | `com.mubi.androidtv` | `assets/icons/com.mubi.androidtv.png` |
| Streaming / TV | Music Videos Free | `com.screencast` | `assets/icons/com.screencast.png` |
| Streaming / TV | MX Player | `com.mxtech.videoplayer.television` | `assets/icons/com.mxtech.videoplayer.television.png` |
| Streaming / TV | NBA | `com.nbaimd.gametime.nba2011` | `assets/icons/com.nbaimd.gametime.nba2011.png` |
| Streaming / TV | NBC | `com.nbc.android.nbctve` | `assets/icons/com.nbc.android.nbctve.png` |
| Streaming / TV | NBC Sports | `com.nbcsports.liveextra` | `assets/icons/com.nbcsports.liveextra.png` |
| Streaming / TV | Netflix | `com.netflix.kepler` | `assets/icons/com.netflix.kepler.png` |
| Streaming / TV | NFL | `com.nfl.fantasy.core.android` | `assets/icons/com.nfl.fantasy.core.android.png` |
| Streaming / TV | Paramount+ | `com.cbs.app` | `assets/icons/com.cbs.app.png` |
| Streaming / TV | Paramount+ | `com.cbs.ott` | `assets/icons/com.cbs.ott.png` |
| Streaming / TV | PBS | `com.pbs.video` | `assets/icons/com.pbs.video.png` |
| Streaming / TV | Peacock | `com.peacocktv.peacockandroid` | `assets/icons/com.peacocktv.peacockandroid.png` |
| Streaming / TV | Philo | `com.philo.philo` | `assets/icons/com.philo.philo.png` |
| Streaming / TV | Pluto TV | `tv.pluto.android` | `assets/icons/tv.pluto.android.png` |
| Streaming / TV | Prime Video | `com.amazon.frenchpress` | `assets/icons/com.amazon.frenchpress.png` |
| Streaming / TV | Pure Flix | `tv.pureflix.android` | `assets/icons/tv.pureflix.android.png` |
| Streaming / TV | Redbox | `com.redbox.android` | `assets/icons/com.redbox.android.png` |
| Streaming / TV | Shudder | `com.shudder.android` | `assets/icons/com.shudder.android.png` |
| Streaming / TV | Sling TV | `com.sling` | `assets/icons/com.sling.png` |
| Streaming / TV | SonyLIV | `com.onemainstream.sonyliv.android` | `assets/icons/com.onemainstream.sonyliv.android.png` |
| Streaming / TV | Spectrum TV | `com.charter.spectrum.guide` | `assets/icons/com.charter.spectrum.guide.png` |
| Streaming / TV | Spotify | `com.spotify.tv.android` | `assets/icons/com.spotify.tv.android.png` |
| Streaming / TV | STARZ | `com.starz.starzplay.android` | `assets/icons/com.starz.starzplay.android.png` |
| Streaming / TV | sunNXT | `com.suntv.sunnxt` | `assets/icons/com.suntv.sunnxt.png` |
| Streaming / TV | TBS | `com.turner.tbs.android.networkapp` | `assets/icons/com.turner.tbs.android.networkapp.png` |
| Streaming / TV | The CW | `com.cw.android.stream` | `assets/icons/com.cw.android.stream.png` |
| Streaming / TV | The Roku Channel | `com.roku.web.trc` | `assets/icons/com.roku.web.trc.png` |
| Streaming / TV | Tubi | `com.tubitv` | `assets/icons/com.tubitv.png` |
| Streaming / TV | Twitch | `com.twitch.android.app` | `assets/icons/com.twitch.android.app.png` |
| Streaming / TV | VLC | `org.videolan.vlc` | `assets/icons/org.videolan.vlc.png` |
| Streaming / TV | Voot | `com.tv.v18.viola` | `assets/icons/com.tv.v18.viola.png` |
| Streaming / TV | Xfinity Stream | `com.xfinity.cloudtvr.tenfoot` | `assets/icons/com.xfinity.cloudtvr.tenfoot.png` |
| Streaming / TV | Xstream Play | `tv.airtel.xstream.tvapp` | `assets/icons/tv.airtel.xstream.tvapp.png` |
| Streaming / TV | Xumo Play | `com.xumo.xumo` | `assets/icons/com.xumo.xumo.png` |
| Streaming / TV | YouTube | `com.amazon.firetv.youtube` | `assets/icons/com.amazon.firetv.youtube.png` |
| Streaming / TV | YouTube TV | `com.google.android.youtube.tvunplugged` | `assets/icons/com.google.android.youtube.tvunplugged.png` |
| Streaming / TV | ZEE5 | `com.zee5.amazon` | `assets/icons/com.zee5.amazon.png` |
| VPN | CyberGhost VPN | `com.cyberghost.android.vpn` | `assets/icons/com.cyberghost.android.vpn.png` |
| VPN | ExpressVPN | `com.expressvpn.vpn` | `assets/icons/com.expressvpn.vpn.png` |
| VPN | HotspotShield VPN | `com.hotspotshield.vpn.android` | `assets/icons/com.hotspotshield.vpn.android.png` |
| VPN | IVPN | `com.ivpn.client` | `assets/icons/com.ivpn.client.png` |
| VPN | Mullvad VPN | `com.mullvad.vpn` | `assets/icons/com.mullvad.vpn.png` |
| VPN | NordVPN | `com.nordvpn.android` | `assets/icons/com.nordvpn.android.png` |
| VPN | OpenVPN Connect | `net.openvpn.openvpn` | `assets/icons/net.openvpn.openvpn.png` |
| VPN | Private Internet Access | `com.privateinternetaccess.android` | `assets/icons/com.privateinternetaccess.android.png` |
| VPN | Proton VPN | `ch.protonvpn.android` | `assets/icons/ch.protonvpn.android.png` |
| VPN | Surfshark | `com.surfshark.vpn.client` | `assets/icons/com.surfshark.vpn.client.png` |
| VPN | TunnelBear | `com.tunnelbear.android` | `assets/icons/com.tunnelbear.android.png` |
| VPN | Windscribe | `com.windscribe.vpn` | `assets/icons/com.windscribe.vpn.png` |

## Adding an icon

1. Add `assets/icons/<packageId>.png` (prefer ~512² Appstore / store art).
2. Add to `BUNDLED_ICONS` in `src/App.tsx`.
3. Add `icon_url_for_pkg` + `emit_app_if_installed` in `scripts/launcher-api-handler.sh` when you have an `m.media-amazon.com/images/I/…` URL.
4. Re-run or edit this catalog; rebuild the vpkg.

