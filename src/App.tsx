import * as React from 'react';
import {useCallback, useEffect, useMemo, useRef, useState} from 'react';
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  Linking,
  Image,
  ImageBackground,
  ImageSourcePropType,
  InteractionManager,
  Modal,
  ScrollView,
  useWindowDimensions,
} from 'react-native';
import {
  useHideSplashScreenCallback,
  usePreventHideSplashScreen,
  useSetLifespanCallback,
  useSetTimeoutCallback,
  useKeplerBackHandler,
  useKeplerAppStateManager,
  useTVEventHandler,
  TVFocusGuideView,
  LIFESPAN_POLICY,
  FocusManager,
} from '@amazon-devices/react-native-kepler';

/** Kepler inactivity timeout in seconds — int32 max ≈ “never sleep / never auto-swap”. */
const LAUNCHER_TIMEOUT_INFINITY_SEC = 2147483647;
import {
  bridgeFetch,
  bridgeFetchFast,
  bridgeLaunch,
  bridgeLaunchKick,
  setBridgeIp,
  startBridgeHostWatcher,
  warmupBridge,
} from './bridge';
import {HomeMetricsPanel} from './HomeMetricsPanel';
import {
  loadDockOrder,
  saveDockOrder,
} from './dockOrderPersistence';
import {useCleanHomeOnHomePress} from './useCleanHomeOnHomePress';
import {useForegroundCleanHome} from './useForegroundCleanHome';
// NOTE: useBootServices (native CleanHomeShell.bootOnce) temporarily disabled —
// it was killing/replacing interactive main with headless boot and breaking dock launches.
/** Material Design 3–inspired TV palette */
const M3 = {
  surface: 'rgba(28, 27, 31, 0.72)',
  surfaceHigh: 'rgba(45, 44, 48, 0.88)',
  onSurface: '#E6E1E5',
  onSurfaceVariant: '#CAC4D0',
  outline: 'rgba(147, 143, 153, 0.45)',
  primary: '#D0BCFF',
  primaryContainer: 'rgba(103, 80, 164, 0.35)',
  focusRing: '#FFFFFF',
};

/** Landscape dock tiles — artwork skewed (stretch) to fill the rectangle; labels below. */
const ICON_WIDTH = 60;
const ICON_HEIGHT = 40;
const ICON_RADIUS = 8;
const SLOT_WIDTH = 68;
const DOCK_GAP = 4;
const LABEL_GAP = 5;
const ICON_SCALE_FOCUSED = 1.28;
const ICON_SCALE_IDLE = 0.94;

const AMAZON_HOME_PKG = 'com.amazon.smplighthouse.launcher';
const CLEAN_SETTINGS_PKG = 'com.cleanhome.launcher.settings';

/** Original store icons — dock tiles prefer these over remote when offline. */
const BUNDLED_ICONS: Record<string, ImageSourcePropType> = {
  'ch.protonvpn.android': require('../assets/icons/ch.protonvpn.android.png'),
  'com.abc.tv.android': require('../assets/icons/com.abc.tv.android.png'),
  'com.acorn.tv': require('../assets/icons/com.acorn.tv.png'),
  'com.aenetworks.lifetime': require('../assets/icons/com.aenetworks.lifetime.png'),
  'com.aftvnews.downloader': require('../assets/icons/com.aftvnews.downloader.png'),
  'com.amazon.firetv.youtube': require('../assets/icons/com.amazon.firetv.youtube.png'),
  'com.amazon.frenchpress': require('../assets/icons/com.amazon.frenchpress.png'),
  'com.amazon.imdb.tv.android.app': require('../assets/icons/com.amazon.imdb.tv.android.app.png'),
  'com.amazon.music.kepler': require('../assets/icons/com.amazon.music.kepler.png'),
  'com.amc.tv': require('../assets/icons/com.amc.tv.png'),
  'com.amcn.amcplus.androidtv': require('../assets/icons/com.amcn.amcplus.androidtv.png'),
  'com.apple.atve.amazon.appletv': require('../assets/icons/com.apple.atve.amazon.appletv.png'),
  'com.att.tv': require('../assets/icons/com.att.tv.png'),
  'com.britbox.us': require('../assets/icons/com.britbox.us.png'),
  'com.bsbportal.music': require('../assets/icons/com.bsbportal.music.png'),
  'com.byutv.android': require('../assets/icons/com.byutv.android.png'),
  'com.cbs.app': require('../assets/icons/com.cbs.app.png'),
  'com.cbs.ott': require('../assets/icons/com.cbs.ott.png'),
  'com.cbssports.android': require('../assets/icons/com.cbssports.android.png'),
  'com.charter.spectrum.guide': require('../assets/icons/com.charter.spectrum.guide.png'),
  'com.cnn.mobile.android.phone': require('../assets/icons/com.cnn.mobile.android.phone.png'),
  'com.crunchyroll.crunchyroid': require('../assets/icons/com.crunchyroll.crunchyroid.png'),
  'com.cw.android.stream': require('../assets/icons/com.cw.android.stream.png'),
  'com.cyberghost.android.vpn': require('../assets/icons/com.cyberghost.android.vpn.png'),
  'com.discovery.discoveryplus.mobile': require('../assets/icons/com.discovery.discoveryplus.mobile.png'),
  'com.disney.disneyplus': require('../assets/icons/com.disney.disneyplus.png'),
  'com.embymedia.emby.tv': require('../assets/icons/com.embymedia.emby.tv.png'),
  'com.espn.score_center': require('../assets/icons/com.espn.score_center.png'),
  'com.expressvpn.vpn': require('../assets/icons/com.expressvpn.vpn.png'),
  'com.fandango': require('../assets/icons/com.fandango.png'),
  'com.fox.android.foxnow': require('../assets/icons/com.fox.android.foxnow.png'),
  'com.fubo.android': require('../assets/icons/com.fubo.android.png'),
  'com.futuretoday.android.filmrise': require('../assets/icons/com.futuretoday.android.filmrise.png'),
  'com.gaia.android': require('../assets/icons/com.gaia.android.png'),
  'com.google.android.youtube.tvunplugged': require('../assets/icons/com.google.android.youtube.tvunplugged.png'),
  'com.hallmarkmoviesnow': require('../assets/icons/com.hallmarkmoviesnow.png'),
  'com.history.watch': require('../assets/icons/com.history.watch.png'),
  'com.hotspotshield.vpn.android': require('../assets/icons/com.hotspotshield.vpn.android.png'),
  'com.hulu.plus': require('../assets/icons/com.hulu.plus.png'),
  'com.ivpn.client': require('../assets/icons/com.ivpn.client.png'),
  'com.jio.media.ondemand': require('../assets/icons/com.jio.media.ondemand.png'),
  'com.kanopy.android': require('../assets/icons/com.kanopy.android.png'),
  'com.mgm.mgmplus': require('../assets/icons/com.mgm.mgmplus.png'),
  'com.mubi.androidtv': require('../assets/icons/com.mubi.androidtv.png'),
  'com.mullvad.vpn': require('../assets/icons/com.mullvad.vpn.png'),
  'com.mxtech.videoplayer.television': require('../assets/icons/com.mxtech.videoplayer.television.png'),
  'com.nbaimd.gametime.nba2011': require('../assets/icons/com.nbaimd.gametime.nba2011.png'),
  'com.nbc.android.nbctve': require('../assets/icons/com.nbc.android.nbctve.png'),
  'com.nbcsports.liveextra': require('../assets/icons/com.nbcsports.liveextra.png'),
  'com.netflix.kepler': require('../assets/icons/com.netflix.kepler.png'),
  'com.nfl.fantasy.core.android': require('../assets/icons/com.nfl.fantasy.core.android.png'),
  'com.nordvpn.android': require('../assets/icons/com.nordvpn.android.png'),
  'com.onemainstream.sonyliv.android': require('../assets/icons/com.onemainstream.sonyliv.android.png'),
  'com.pbs.video': require('../assets/icons/com.pbs.video.png'),
  'com.peacocktv.peacockandroid': require('../assets/icons/com.peacocktv.peacockandroid.png'),
  'com.philo.philo': require('../assets/icons/com.philo.philo.png'),
  'com.plexapp.android': require('../assets/icons/com.plexapp.android.png'),
  'com.privateinternetaccess.android': require('../assets/icons/com.privateinternetaccess.android.png'),
  'com.redbox.android': require('../assets/icons/com.redbox.android.png'),
  'com.roku.web.trc': require('../assets/icons/com.roku.web.trc.png'),
  'com.screencast': require('../assets/icons/com.screencast.png'),
  'com.shudder.android': require('../assets/icons/com.shudder.android.png'),
  'com.sling': require('../assets/icons/com.sling.png'),
  'com.spotify.tv.android': require('../assets/icons/com.spotify.tv.android.png'),
  'com.starz.starzplay.android': require('../assets/icons/com.starz.starzplay.android.png'),
  'com.suntv.sunnxt': require('../assets/icons/com.suntv.sunnxt.png'),
  'com.surfshark.vpn.client': require('../assets/icons/com.surfshark.vpn.client.png'),
  'com.tubitv': require('../assets/icons/com.tubitv.png'),
  'com.tunnelbear.android': require('../assets/icons/com.tunnelbear.android.png'),
  'com.turner.tbs.android.networkapp': require('../assets/icons/com.turner.tbs.android.networkapp.png'),
  'com.tv.v18.viola': require('../assets/icons/com.tv.v18.viola.png'),
  'com.twitch.android.app': require('../assets/icons/com.twitch.android.app.png'),
  'com.wbd.stream': require('../assets/icons/com.wbd.stream.png'),
  'com.windscribe.vpn': require('../assets/icons/com.windscribe.vpn.png'),
  'com.xfinity.cloudtvr.tenfoot': require('../assets/icons/com.xfinity.cloudtvr.tenfoot.png'),
  'com.xumo.xumo': require('../assets/icons/com.xumo.xumo.png'),
  'com.zee5.amazon': require('../assets/icons/com.zee5.amazon.png'),
  'in.AajTak.headlines': require('../assets/icons/in.AajTak.headlines.png'),
  'in.startv.hotstar': require('../assets/icons/in.startv.hotstar.png'),
  'net.openvpn.openvpn': require('../assets/icons/net.openvpn.openvpn.png'),
  'org.jellyfin.androidtv': require('../assets/icons/org.jellyfin.androidtv.png'),
  'org.jellyfin.mobile': require('../assets/icons/org.jellyfin.mobile.png'),
  'org.videolan.vlc': require('../assets/icons/org.videolan.vlc.png'),
  'org.xbmc.kodi': require('../assets/icons/org.xbmc.kodi.png'),
  'tv.airtel.xstream.tvapp': require('../assets/icons/tv.airtel.xstream.tvapp.png'),
  'tv.fawesome.android': require('../assets/icons/tv.fawesome.android.png'),
  'tv.pluto.android': require('../assets/icons/tv.pluto.android.png'),
  'tv.pureflix.android': require('../assets/icons/tv.pureflix.android.png'),
  'com.cleanhome.launcher.settings': require('../assets/icons/com.amazon.vegatvsettings.png'),
  'com.amazon.smplighthouse.launcher': require('../assets/icons/com.amazon.appstorevegatv.png'),
  'com.amazon.appstorevegatv': require('../assets/icons/com.amazon.appstorevegatv.png'),
  'com.amazon.vegatvsettings': require('../assets/icons/com.amazon.vegatvsettings.png'),
};


type DockApp = {
  packageId: string;
  component: string;
  title: string;
  asin: string;
  /** Optional store artwork from bridge /apps (ASIN CDN). */
  iconUrl?: string;
};

/** Always at the end of the dock. */
const PINNED_APPS: DockApp[] = [
  {
    packageId: CLEAN_SETTINGS_PKG,
    component: 'com.cleanhome.launcher.settings',
    title: 'Settings',
    asin: '',
  },
  {
    packageId: AMAZON_HOME_PKG,
    component: 'com.amazon.smplighthouse.launcher.main',
    title: 'FireTV',
    asin: '',
  },
];

/**
 * Local seed so the dock is never empty if /apps is slow or blocked.
 * Replaced by live bridge list when /apps succeeds.
 */
const SEED_MEDIA_APPS: DockApp[] = [
  {
    packageId: 'com.amazon.frenchpress',
    component: 'com.amazon.frenchpress.main',
    title: 'Prime Video',
    asin: '',
  },
  {
    packageId: 'com.netflix.kepler',
    component: 'com.netflix.kepler.main',
    title: 'Netflix',
    asin: '',
  },
  {
    packageId: 'com.suntv.sunnxt',
    component: 'com.suntv.sunnxt.main',
    title: 'sunNXT',
    asin: '',
  },
  {
    packageId: 'com.amazon.firetv.youtube',
    component: 'com.amazon.firetv.youtube.main',
    title: 'YouTube',
    asin: '',
  },
  {
    packageId: 'com.onemainstream.sonyliv.android',
    component: 'com.onemainstream.sonyliv.android.main',
    title: 'SonyLiv',
    asin: '',
  },
  {
    packageId: 'com.apple.atve.amazon.appletv',
    component: 'com.apple.atve.amazon.appletv.main',
    title: 'AppleTV',
    asin: '',
  },
  {
    packageId: 'in.startv.hotstar',
    component: 'in.startv.hotstar.main',
    title: 'Jio Hotstar',
    asin: '',
  },
  {
    packageId: 'com.zee5.amazon',
    component: 'com.zee5.amazon.main',
    title: 'Zee5',
    asin: '',
  },
  {
    packageId: 'com.crunchyroll.crunchyroid',
    component: 'com.crunchyroll.crunchyroid.main',
    title: 'Crunchyroll',
    asin: '',
  },
  {
    packageId: 'tv.airtel.xstream.tvapp',
    component: 'tv.airtel.xstream.tvapp.main',
    title: 'Xstream Play',
    asin: '',
  },
  {
    packageId: 'com.amazon.music.kepler',
    component: 'com.amazon.music.kepler.main',
    title: 'Amazon Music',
    asin: '',
  },
];

const SEED_DOCK_APPS: DockApp[] = [...SEED_MEDIA_APPS, ...PINNED_APPS];

/** OK held this long opens the dock menu (release OK after — menu stays open). */
const LONG_PRESS_MS = 420;

function reorderDockIds(ids: string[], packageId: string, targetIndex: number): string[] {
  const from = ids.indexOf(packageId);
  if (from < 0) {
    return ids;
  }
  let to = targetIndex;
  if (to < 0) {
    to = 0;
  }
  if (to >= ids.length) {
    to = ids.length - 1;
  }
  const next = [...ids];
  const [removed] = next.splice(from, 1);
  let insertAt = to;
  if (to > from) {
    insertAt = to - 1;
  }
  next.splice(insertAt, 0, removed);
  return next;
}

/** Prefer live /apps list; always keep Settings then Amazon Home at the end. */
function buildDockFromRemote(remote: DockApp[]): DockApp[] {
  const byId = new Map<string, DockApp>();
  for (const app of remote) {
    if (!app?.packageId) {
      continue;
    }
    byId.set(app.packageId, {
      packageId: app.packageId,
      component: app.component || `${app.packageId}.main`,
      title: app.title || app.packageId,
      asin: app.asin || '',
      iconUrl: app.iconUrl || '',
    });
  }
  for (const pin of PINNED_APPS) {
    const existing = byId.get(pin.packageId);
    // Pinned titles win (e.g. FireTV, not bridge "Amazon Home").
    byId.set(
      pin.packageId,
      existing ? {...pin, ...existing, title: pin.title} : pin,
    );
  }
  const rest = [...byId.values()].filter(
    a => a.packageId !== AMAZON_HOME_PKG && a.packageId !== CLEAN_SETTINGS_PKG,
  );
  const settings = byId.get(CLEAN_SETTINGS_PKG) ?? PINNED_APPS[0];
  const amazon = byId.get(AMAZON_HOME_PKG) ?? PINNED_APPS[1];
  return [...rest, settings, amazon];
}

function applyOrder(apps: DockApp[], order: string[]): DockApp[] {
  const map = new Map(apps.map(a => [a.packageId, a]));
  const pinned = [CLEAN_SETTINGS_PKG, AMAZON_HOME_PKG];
  const ordered: DockApp[] = [];
  for (const id of order) {
    if (pinned.includes(id)) {
      continue;
    }
    const item = map.get(id);
    if (item) {
      ordered.push(item);
      map.delete(id);
    }
  }
  for (const item of map.values()) {
    if (!pinned.includes(item.packageId)) {
      ordered.push(item);
    }
  }
  for (const id of pinned) {
    const item = map.get(id) ?? apps.find(a => a.packageId === id);
    if (item) {
      ordered.push(item);
    }
  }
  return ordered;
}

function DockTile({
  displayApp,
  index,
  focused,
  wantPreferredFocus,
  onBecameFocused,
  onOpenApp,
  onOpenOptions,
  moveModeActive,
  showEmptySlot,
  movePreview,
  onPlaceAt,
  tileRef,
}: {
  displayApp: DockApp;
  index: number;
  focused: boolean;
  wantPreferredFocus: boolean;
  onBecameFocused: (index: number) => void;
  onOpenApp: (item: DockApp) => void;
  onOpenOptions: (index: number) => void;
  moveModeActive: boolean;
  showEmptySlot: boolean;
  movePreview: boolean;
  onPlaceAt: (index: number) => void;
  tileRef?: React.Ref<React.ComponentRef<typeof Pressable>>;
}) {
  const holdTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const holdOpenedRef = useRef(false);
  const scale = focused || movePreview ? ICON_SCALE_FOCUSED : ICON_SCALE_IDLE;
  let opacity = focused ? 1 : 0.78;
  if (moveModeActive && !focused && !showEmptySlot) {
    opacity = 0.45;
  }
  if (showEmptySlot) {
    opacity = 0.22;
  }
  const canOptions = displayApp.packageId !== AMAZON_HOME_PKG;

  const clearHoldTimer = () => {
    if (holdTimerRef.current) {
      clearTimeout(holdTimerRef.current);
      holdTimerRef.current = null;
    }
  };

  const startHoldTimer = () => {
    if (!canOptions || moveModeActive) {
      return;
    }
    clearHoldTimer();
    holdOpenedRef.current = false;
    holdTimerRef.current = setTimeout(() => {
      holdTimerRef.current = null;
      holdOpenedRef.current = true;
      onOpenOptions(index);
    }, LONG_PRESS_MS);
  };

  useEffect(() => () => clearHoldTimer(), []);

  return (
    <Pressable
      ref={tileRef}
      focusable
      android_disableSound
      hasTVPreferredFocus={wantPreferredFocus}
      delayLongPress={LONG_PRESS_MS}
      onFocus={() => onBecameFocused(index)}
      onPressIn={startHoldTimer}
      onPressOut={clearHoldTimer}
      onLongPress={() => {
        if (!canOptions) {
          return;
        }
        holdOpenedRef.current = true;
        clearHoldTimer();
        onOpenOptions(index);
      }}
      onPress={() => {
        if (holdOpenedRef.current) {
          holdOpenedRef.current = false;
          return;
        }
        if (moveModeActive) {
          onPlaceAt(index);
          return;
        }
        onOpenApp(displayApp);
      }}
      style={[
        styles.dockTile,
        movePreview && styles.dockTilePlaceTarget,
        {opacity, zIndex: focused || movePreview ? 20 : 1},
      ]}>
      {showEmptySlot ? (
        <View
          style={[
            styles.iconShadow,
            styles.iconShadowEmpty,
            {transform: [{scale: ICON_SCALE_IDLE}]},
          ]}
          pointerEvents="none"
        />
      ) : (
        <>
          <View
            style={[
              styles.iconShadow,
              movePreview && styles.iconShadowMoving,
              {transform: [{scale}]},
            ]}
            pointerEvents="none">
            <AppIcon app={displayApp} />
          </View>
          <Text
            style={[
              styles.dockTileLabel,
              (focused || movePreview) && styles.dockTileLabelFocused,
            ]}
            numberOfLines={1}>
            {displayApp.title}
          </Text>
        </>
      )}
    </Pressable>
  );
}

function pickDockIcon(packageId: string): ImageSourcePropType | null {
  return BUNDLED_ICONS[packageId] ?? null;
}

function AppIcon({app}: {app: DockApp}) {
  const local = pickDockIcon(app.packageId);
  const remote = (app.iconUrl || '').trim();
  const remoteOk =
    /^https?:\/\//i.test(remote) &&
    !/amazon-adsystem\.com/i.test(remote);

  // Prefer store art; skew into landscape tile (stretch, not crop). Name tile if none.
  if (remoteOk) {
    return (
      <Image
        source={{uri: remote}}
        defaultSource={local ?? undefined}
        style={styles.iconImg}
        resizeMode="stretch"
      />
    );
  }
  if (local) {
    return (
      <Image source={local} style={styles.iconImg} resizeMode="stretch" />
    );
  }
  return (
    <View style={[styles.iconImg, styles.iconFallback]}>
      <Text style={styles.iconName} numberOfLines={2}>
        {app.title || app.packageId}
      </Text>
    </View>
  );
}

export const App = () => {
  usePreventHideSplashScreen();
  const hideSplashScreen = useHideSplashScreenCallback();
  const setAppTimeout = useSetTimeoutCallback();
  const setAppLifespan = useSetLifespanCallback();
  const appStateManager = useKeplerAppStateManager();
  const keplerBackHandler = useKeplerBackHandler();
  const [apps, setApps] = useState<DockApp[]>(SEED_DOCK_APPS);
  const [order, setOrder] = useState<string[]>([]);
  const [focusedIndex, setFocusedIndex] = useState(0);
  const [now, setNow] = useState(() => new Date());
  const [uiReady, setUiReady] = useState(false);
  const {width: windowWidth} = useWindowDimensions();
  const dockScrollRef = useRef<ScrollView>(null);
  // Home / amazon_mode hooks — enable after launch is stable on-device.
  useCleanHomeOnHomePress(uiReady);
  // useForegroundCleanHome(); // was racing resume-default during first paint

  useEffect(() => {
    // Warm bridge immediately so dock OK works soon after reboot.
    warmupBridge();
    const stop = startBridgeHostWatcher();
    return () => {
      stop();
    };
  }, []);

  /** Keep focused dock tile in view — left-aligned flow; first stays leftmost until far right. */
  const scrollDockToIndex = useCallback(
    (index: number) => {
      const stride = SLOT_WIDTH + DOCK_GAP;
      const pad = 28;
      const viewW = Math.max(320, windowWidth - pad * 2);
      // Show ~2 tiles of context to the left once we leave the start.
      const ideal = Math.max(0, index * stride - stride * 2);
      const maxScroll = Math.max(0, dockAppsRef.current.length * stride - viewW + pad);
      const x = Math.min(ideal, maxScroll);
      dockScrollRef.current?.scrollTo({x, animated: true});
    },
    [windowWidth],
  );

  // Re-assert permanent lifespan + infinite timeout whenever Clean Home is focused.
  useEffect(() => {
    const applyNoSleep = () => {
      try {
        setAppLifespan(LIFESPAN_POLICY.PERMANENT);
        setAppTimeout(LAUNCHER_TIMEOUT_INFINITY_SEC);
      } catch {
        // optional on this build
      }
      bridgeFetch('/keep-awake').catch(() => {});
    };
    applyNoSleep();
    let subFocus: {remove: () => void} | null = null;
    let subChange: {remove: () => void} | null = null;
    try {
      subFocus = appStateManager.addEventListener('focus', applyNoSleep);
      subChange = appStateManager.addEventListener('change', state => {
        if (state === 'active') {
          applyNoSleep();
        }
      });
    } catch {
      // optional
    }
    return () => {
      subFocus?.remove();
      subChange?.remove();
    };
  }, [appStateManager, setAppLifespan, setAppTimeout]);

  const [searchFocused, setSearchFocused] = useState(false);
  const [dockMenuOpen, setDockMenuOpen] = useState(false);
  const [menuFocusIndex, setMenuFocusIndex] = useState(0);
  const [moveModePackageId, setMoveModePackageId] = useState<string | null>(null);
  const [moveFocusLatch, setMoveFocusLatch] = useState<number | null>(null);
  const openingRef = useRef(false);
  const dockAppsRef = useRef<DockApp[]>(SEED_DOCK_APPS);
  const dockMenuOpenRef = useRef(false);
  const searchFocusedRef = useRef(false);
  const focusedIndexRef = useRef(0);
  const moveModeRef = useRef<string | null>(null);
  const initDone = useRef(false);
  const initialDockFocusDone = useRef(false);
  const dockTileRefs = useRef<Array<React.ComponentRef<typeof Pressable> | null>>(
    [],
  );
  const [preferredFocusIndex, setPreferredFocusIndex] = useState<number | null>(
    null,
  );
  const searchRef = useRef<React.ComponentRef<typeof Pressable>>(null);
  const firstDockRef = useRef<React.ComponentRef<typeof Pressable>>(null);
  const hideSplashRef = useRef(hideSplashScreen);
  const setLifespanRef = useRef(setAppLifespan);
  const setTimeoutRef = useRef(setAppTimeout);

  const dockApps = useMemo(
    () => applyOrder(apps, order.length ? order : apps.map(a => a.packageId)),
    [apps, order],
  );

  dockAppsRef.current = dockApps;
  dockMenuOpenRef.current = dockMenuOpen;
  searchFocusedRef.current = searchFocused;
  focusedIndexRef.current = focusedIndex;
  moveModeRef.current = moveModePackageId;

  const assignDockTileRef = useCallback(
    (index: number) => (node: React.ComponentRef<typeof Pressable> | null) => {
      dockTileRefs.current[index] = node;
      if (index === 0) {
        firstDockRef.current = node;
      }
    },
    [],
  );

  const scheduleDockFocus = useCallback(
    (index: number) => {
      const clamped = Math.max(0, Math.min(index, dockAppsRef.current.length - 1));
      setPreferredFocusIndex(clamped);
      setFocusedIndex(clamped);
      scrollDockToIndex(clamped);
      requestAnimationFrame(() => {
        try {
          dockTileRefs.current[clamped]?.requestTVFocus?.();
        } catch {
          // TV focus optional
        }
      });
      setTimeout(() => {
        setPreferredFocusIndex(prev => (prev === clamped ? null : prev));
      }, 350);
    },
    [scrollDockToIndex],
  );

  const closeDockMenu = useCallback(() => {
    setDockMenuOpen(false);
    scheduleDockFocus(focusedIndexRef.current);
  }, [scheduleDockFocus]);

  const openDockMenu = useCallback((index?: number) => {
    if (moveModeRef.current) {
      return;
    }
    const idx = index ?? focusedIndexRef.current;
    const item = dockAppsRef.current[idx];
    if (!item || item.packageId === AMAZON_HOME_PKG) {
      return;
    }
    setFocusedIndex(idx);
    setMenuFocusIndex(0);
    setDockMenuOpen(true);
  }, []);

  const persistOrder = useCallback((ids: string[]) => {
    const cleaned = ids.filter(Boolean);
    setOrder(cleaned);
    saveDockOrder(cleaned).catch(() => {});
  }, []);

  const startMoveMode = useCallback((sourceIndex: number) => {
    const pkg = dockAppsRef.current[sourceIndex]?.packageId;
    if (!pkg || pkg === AMAZON_HOME_PKG) {
      return;
    }
    setDockMenuOpen(false);
    setMoveModePackageId(pkg);
    setFocusedIndex(sourceIndex);
    setMoveFocusLatch(sourceIndex);
    scheduleDockFocus(sourceIndex);
  }, [scheduleDockFocus]);

  const placeMovedApp = useCallback(
    (targetIndex: number) => {
      const pkg = moveModePackageId;
      if (!pkg) {
        return;
      }
      const ids = dockAppsRef.current.map(a => a.packageId);
      const next = reorderDockIds(ids, pkg, targetIndex);
      persistOrder(next);
      const newIndex = next.indexOf(pkg);
      setMoveModePackageId(null);
      setMoveFocusLatch(null);
      if (newIndex >= 0) {
        setFocusedIndex(newIndex);
      }
    },
    [moveModePackageId, persistOrder],
  );

  const cancelMoveMode = useCallback(() => {
    setMoveModePackageId(null);
    setMoveFocusLatch(null);
  }, []);

  const runSearch = useCallback(async (query: string) => {
    openingRef.current = true;
    const q = query.trim();
    const path = q
      ? `/search?q=${encodeURIComponent(q)}`
      : '/search';
    await bridgeFetch(path);
    setTimeout(() => {
      openingRef.current = false;
    }, 800);
  }, []);

  const refreshClock = useCallback(() => {
    setNow(new Date());
  }, []);

  hideSplashRef.current = hideSplashScreen;
  setLifespanRef.current = setAppLifespan;
  setTimeoutRef.current = setAppTimeout;

  useEffect(() => {
    if (initDone.current) {
      return;
    }
    initDone.current = true;
    setLifespanRef.current(LIFESPAN_POLICY.PERMANENT);
    setTimeoutRef.current(LAUNCHER_TIMEOUT_INFINITY_SEC);
    let cancelled = false;
    const task = InteractionManager.runAfterInteractions(() => {
      setUiReady(true);
      hideSplashRef.current();
      warmupBridge();

      const applyAppsPayload = async (res: Response | null) => {
        if (!res || cancelled) {
          return false;
        }
        try {
          const data = (await res.json()) as {ok?: boolean; apps?: DockApp[]};
          if (data.ok && data.apps?.length) {
            setApps(buildDockFromRemote(data.apps));
            return true;
          }
        } catch (_e) {
          // keep seed dock
        }
        return false;
      };

      // Fast path first (seed host) — avoid awaiting host probe that can stall on file://.
      const loadRemoteDock = async () => {
        const attempts = [0, 800, 2000, 5000];
        for (const delay of attempts) {
          if (cancelled) {
            return;
          }
          if (delay) {
            await new Promise<void>(r => setTimeout(r, delay));
          }
          if (cancelled) {
            return;
          }
          const res = await bridgeFetchFast('/apps', 2500);
          if (await applyAppsPayload(res)) {
            bridgeFetchFast('/keep-awake').catch(() => {});
            return;
          }
        }
        // Last resort: full host refresh path
        const slow = await bridgeFetch('/apps');
        if (await applyAppsPayload(slow)) {
          bridgeFetch('/keep-awake').catch(() => {});
        }
      };
      void loadRemoteDock();
    });
    loadDockOrder()
      .then(saved => {
        if (saved?.length) {
          setOrder(saved);
        }
      })
      .catch(() => {});
    return () => {
      cancelled = true;
      task.cancel();
    };
  }, []);

  useEffect(() => {
    refreshClock();
    const tick = setInterval(refreshClock, 60_000);
    return () => clearInterval(tick);
  }, [refreshClock]);

  useEffect(() => {
    if (!uiReady || dockMenuOpen || moveModePackageId) {
      return;
    }
    const search = searchRef.current;
    const dock = firstDockRef.current;
    if (search && dock) {
      try {
        FocusManager.setNextFocus(search, dock, 'down');
        FocusManager.setNextFocus(dock, search, 'up');
      } catch {
        // focus graph optional
      }
    }
  }, [uiReady, dockMenuOpen, moveModePackageId]);

  useEffect(() => {
    if (!uiReady || initialDockFocusDone.current || dockMenuOpen) {
      return;
    }
    initialDockFocusDone.current = true;
    const timer = setTimeout(() => scheduleDockFocus(0), 150);
    return () => clearTimeout(timer);
  }, [uiReady, dockMenuOpen, scheduleDockFocus]);

  useTVEventHandler(evt => {
    if (evt.eventKeyAction === 1) {
      return;
    }
    if (
      moveModeRef.current ||
      dockMenuOpenRef.current ||
      searchFocusedRef.current
    ) {
      return;
    }
    if (
      evt.eventType === 'menu' ||
      evt.eventType === 'context_menu' ||
      evt.eventType === 'root_menu'
    ) {
      openDockMenu();
    }
  });

  useEffect(() => {
    const sub = keplerBackHandler.addEventListener('hardwareBackPress', () => {
      if (moveModePackageId) {
        cancelMoveMode();
        return true;
      }
      if (dockMenuOpen) {
        closeDockMenu();
        return true;
      }
      bridgeFetch('/resume-default').catch(() => {});
      return true;
    });
    return () => sub.remove();
  }, [
    cancelMoveMode,
    closeDockMenu,
    dockMenuOpen,
    keplerBackHandler,
    moveModePackageId,
  ]);

  const openApp = useCallback(
    async (item: DockApp) => {
      if (openingRef.current || moveModeRef.current) {
        return;
      }
      openingRef.current = true;

      const component = item.component;
      const uri = `pkg://${component}`;

      try {
        // Settings dock → Wi‑Fi / BT network HUD (not full Settings, not amazon_mode).
        if (item.packageId === CLEAN_SETTINGS_PKG) {
          bridgeLaunchKick('com.amazon.vegatvsettings.hud');
          void bridgeFetchFast('/network-panel').then(async res => {
            if (!res) {
              try {
                await Linking.openURL('pkg://com.amazon.vegatvsettings.hud');
              } catch (_e) {
                // ignore
              }
            }
          });
          try {
            await Linking.openURL('pkg://com.amazon.vegatvsettings.hud');
          } catch (_e1) {
            // bridge kick already sent
          }
          return;
        }

        // Amazon Home: MUST set amazon_mode before smpl is visible or home.sh yanks back.
        if (item.packageId === AMAZON_HOME_PKG) {
          const smpl = 'pkg://com.amazon.smplighthouse.launcher.main';
          // Fire /amazon-home first (sets flag); never open smpl without it.
          const flagged = await bridgeFetchFast('/amazon-home', 2500);
          let openedByBridge = false;
          if (flagged) {
            try {
              const data = (await flagged.json()) as {ok?: boolean; ip?: string};
              if (data.ip) {
                setBridgeIp(data.ip).catch(() => {});
              }
              openedByBridge = data.ok === true;
            } catch (_e) {
              // fall through
            }
          }
          if (!openedByBridge) {
            // Retry once so flag is on disk before Linking.
            await bridgeFetch('/amazon-home').catch(() => {});
            try {
              await Linking.openURL(smpl);
            } catch (_e1) {
              bridgeLaunchKick('com.amazon.smplighthouse.launcher.main');
            }
          }
          return;
        }

        // Prefer bridge /launch (works after reboot). Linking alone often no-ops
        // when the bridge host was a bad seed (0.0.0.0) or sandbox blocks pkg://.
        bridgeLaunchKick(component);
        const launched = await bridgeLaunch(component);
        if (!launched) {
          try {
            await Linking.openURL(uri);
          } catch (_e1) {
            try {
              await Linking.openURL(`orpheus://${component}`);
            } catch (_e2) {
              // bridge kick already attempted
            }
          }
        }
      } finally {
        setTimeout(() => {
          openingRef.current = false;
        }, 400);
      }
    },
    [],
  );

  const focusedApp = dockApps[focusedIndex] ?? dockApps[0];
  const movingApp =
    moveModePackageId != null
      ? dockApps.find(a => a.packageId === moveModePackageId)
      : undefined;
  const moveSourceIndex =
    moveModePackageId != null
      ? dockApps.findIndex(a => a.packageId === moveModePackageId)
      : -1;

  if (!uiReady) {
    return <View style={styles.root} />;
  }

  return (
    <ImageBackground
      source={require('../assets/wallpaper.jpg')}
      style={styles.root}
      resizeMode="cover">
      <View style={styles.screenColumn}>
        <View style={styles.headerZone} pointerEvents="box-none">
          <View style={styles.topBar} pointerEvents="box-none">
            <Pressable
              ref={searchRef}
              focusable
              android_disableSound
              hasTVPreferredFocus={false}
              onFocus={() => {
                setSearchFocused(true);
              }}
              onBlur={() => setSearchFocused(false)}
              onPress={() => runSearch('')}
              style={[
                styles.searchShell,
                searchFocused && styles.searchShellFocused,
              ]}>
              <Text style={styles.searchIcon}>⌕</Text>
              <Text style={styles.searchLabel}>Search movies & shows</Text>
            </Pressable>

            <HomeMetricsPanel now={now} />
          </View>
        </View>

        <View style={styles.hero} pointerEvents="none" />

        <View style={styles.bottomPanel}>
        <Modal
          visible={dockMenuOpen}
          transparent
          animationType="fade"
          onRequestClose={closeDockMenu}>
          <View style={styles.menuBackdrop}>
            <TVFocusGuideView
              autoFocus
              trapFocusUp
              trapFocusDown
              trapFocusLeft
              trapFocusRight
              style={styles.menuGuide}>
              <Text style={styles.menuTitle}>
                {focusedApp?.title ?? 'App'} options
              </Text>
              <View style={styles.dockMenuRow}>
                <Pressable
                  focusable
                  hasTVPreferredFocus={menuFocusIndex === 0}
                  onFocus={() => setMenuFocusIndex(0)}
                  onPress={() => startMoveMode(focusedIndex)}
                  style={[
                    styles.dockMenuChip,
                    menuFocusIndex === 0 && styles.dockMenuChipFocused,
                  ]}>
                  <Text style={styles.dockMenuChipText}>Move</Text>
                </Pressable>
                <Pressable
                  focusable
                  hasTVPreferredFocus={menuFocusIndex === 1}
                  onFocus={() => setMenuFocusIndex(1)}
                  onPress={closeDockMenu}
                  style={[
                    styles.dockMenuChip,
                    menuFocusIndex === 1 && styles.dockMenuChipFocused,
                  ]}>
                  <Text style={styles.dockMenuChipText}>Close</Text>
                </Pressable>
              </View>
            </TVFocusGuideView>
          </View>
        </Modal>

        <TVFocusGuideView
          trapFocusLeft
          trapFocusRight
          style={styles.dockGuide}>
          <ScrollView
            ref={dockScrollRef}
            horizontal
            showsHorizontalScrollIndicator={false}
            showsVerticalScrollIndicator={false}
            bounces={false}
            overScrollMode="never"
            keyboardShouldPersistTaps="handled"
            style={styles.dockScroll}
            contentContainerStyle={styles.dockRow}>
            {dockApps.map((item, index) => {
              const focused = focusedIndex === index;
              const inMove = moveModePackageId != null && movingApp != null;
              const showEmptySlot =
                inMove &&
                index === moveSourceIndex &&
                index !== focusedIndex;
              const movePreview = inMove && index === focusedIndex;
              const displayApp =
                movePreview && movingApp ? movingApp : item;
              const wantMoveFocus = moveFocusLatch === index;
              const wantRestoreFocus =
                !dockMenuOpen &&
                !moveModePackageId &&
                preferredFocusIndex === index;
              return (
                <DockTile
                  key={item.packageId}
                  displayApp={displayApp}
                  index={index}
                  focused={focused}
                  tileRef={assignDockTileRef(index)}
                  wantPreferredFocus={wantMoveFocus || wantRestoreFocus}
                  moveModeActive={inMove}
                  showEmptySlot={showEmptySlot}
                  movePreview={movePreview}
                  onPlaceAt={placeMovedApp}
                  onBecameFocused={i => {
                    if (moveFocusLatch != null) {
                      setMoveFocusLatch(null);
                    }
                    if (preferredFocusIndex === i) {
                      setPreferredFocusIndex(null);
                    }
                    setSearchFocused(false);
                    setFocusedIndex(i);
                    scrollDockToIndex(i);
                  }}
                  onOpenApp={openApp}
                  onOpenOptions={i => openDockMenu(i)}
                />
              );
            })}
          </ScrollView>
        </TVFocusGuideView>
      </View>
      </View>
    </ImageBackground>
  );
};

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#000',
  },
  screenColumn: {
    flex: 1,
    flexDirection: 'column',
  },
  headerZone: {
    paddingTop: 40,
    paddingHorizontal: 56,
    flexShrink: 0,
  },
  topBar: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    width: '100%',
  },
  rightHeaderCol: {
    alignItems: 'flex-end',
    maxWidth: '48%',
  },
  statsColumn: {
    alignSelf: 'flex-end',
    marginTop: 8,
    alignItems: 'flex-start',
    minWidth: 210,
  },
  headerStats: {
    color: 'rgba(255,255,255,0.88)',
    fontSize: 11,
    fontWeight: '500',
    marginTop: 2,
    textAlign: 'left',
    alignSelf: 'stretch',
    textShadowColor: 'rgba(0,0,0,0.65)',
    textShadowOffset: {width: 0, height: 1},
    textShadowRadius: 4,
  },
  headerStatsSub: {
    color: 'rgba(255,255,255,0.88)',
    fontSize: 11,
    fontWeight: '500',
    marginTop: 2,
    textAlign: 'left',
    alignSelf: 'stretch',
    paddingLeft: 72,
    textShadowColor: 'rgba(0,0,0,0.65)',
    textShadowOffset: {width: 0, height: 1},
    textShadowRadius: 4,
  },
  dateTimeBlock: {
    alignItems: 'flex-end',
    paddingTop: 2,
    minWidth: 140,
  },
  dateText: {
    color: 'rgba(255,255,255,0.82)',
    fontSize: 15,
    fontWeight: '500',
    textShadowColor: 'rgba(0,0,0,0.65)',
    textShadowOffset: {width: 0, height: 1},
    textShadowRadius: 4,
  },
  timeText: {
    color: '#FFFFFF',
    fontSize: 26,
    fontWeight: '600',
    marginTop: 2,
    textShadowColor: 'rgba(0,0,0,0.65)',
    textShadowOffset: {width: 0, height: 1},
    textShadowRadius: 4,
  },
  searchShell: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: M3.surfaceHigh,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.12)',
    paddingHorizontal: 18,
    height: 44,
    minWidth: 280,
    maxWidth: 400,
  },
  searchShellFocused: {
    borderColor: M3.primary,
    backgroundColor: 'rgba(45,44,48,0.95)',
    transform: [{scale: 1.03}],
  },
  searchIcon: {
    color: M3.primary,
    fontSize: 22,
    marginRight: 10,
  },
  searchLabel: {
    color: M3.onSurface,
    fontSize: 15,
    fontWeight: '500',
  },
  hero: {
    flex: 1,
    minHeight: 48,
  },
  bottomPanel: {
    flexShrink: 0,
    paddingBottom: 36,
    alignItems: 'center',
  },
  bottomPanelHidden: {
    opacity: 0,
    height: 0,
    overflow: 'hidden',
    paddingBottom: 0,
  },
  dockGuide: {
    width: '100%',
    alignItems: 'stretch',
  },
  dockScroll: {
    width: '100%',
    flexGrow: 0,
  },
  dockRow: {
    flexDirection: 'row',
    flexWrap: 'nowrap',
    justifyContent: 'flex-start',
    alignItems: 'flex-end',
    paddingHorizontal: 28,
    paddingVertical: 6,
    gap: DOCK_GAP,
    minHeight: 72,
  },
  dockTile: {
    width: SLOT_WIDTH,
    minHeight: 64,
    alignItems: 'center',
    justifyContent: 'flex-start',
    backgroundColor: 'transparent',
    borderWidth: 0,
  },
  dockTilePlaceTarget: {
    opacity: 0.92,
  },
  iconShadow: {
    width: ICON_WIDTH,
    height: ICON_HEIGHT,
    borderRadius: ICON_RADIUS,
    overflow: 'hidden',
    backgroundColor: 'rgba(22, 21, 26, 0.92)',
  },
  iconShadowEmpty: {
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.18)',
    borderStyle: 'dashed',
  },
  iconShadowMoving: {
    borderWidth: 2,
    borderColor: M3.primary,
    borderStyle: 'dashed',
  },
  iconImg: {
    width: ICON_WIDTH,
    height: ICON_HEIGHT,
    borderRadius: ICON_RADIUS,
  },
  iconFallback: {
    backgroundColor: M3.surfaceHigh,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: M3.outline,
  },
  iconLetter: {
    color: M3.onSurface,
    fontSize: 18,
    fontWeight: '700',
  },
  iconName: {
    color: M3.onSurface,
    fontSize: 9,
    fontWeight: '600',
    textAlign: 'center',
    paddingHorizontal: 4,
  },
  dockTileLabel: {
    marginTop: LABEL_GAP,
    maxWidth: SLOT_WIDTH,
    color: 'rgba(255,255,255,0.72)',
    fontSize: 9,
    fontWeight: '600',
    textAlign: 'center',
    textShadowColor: 'rgba(0,0,0,0.85)',
    textShadowRadius: 4,
    textShadowOffset: {width: 0, height: 1},
  },
  dockTileLabelFocused: {
    color: '#FFFFFF',
    fontSize: 10,
  },
  menuBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.72)',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  menuGuide: {
    width: '100%',
    maxWidth: 920,
    alignItems: 'center',
  },
  menuTitle: {
    color: '#FFFFFF',
    fontSize: 22,
    fontWeight: '700',
    marginBottom: 20,
    textAlign: 'center',
  },
  dockMenuRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    maxWidth: '100%',
    marginBottom: 12,
  },
  dockMenuChip: {
    backgroundColor: M3.surfaceHigh,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: M3.outline,
    paddingHorizontal: 14,
    paddingVertical: 8,
    marginHorizontal: 4,
    marginVertical: 4,
  },
  dockMenuChipFocused: {
    borderColor: M3.primary,
    backgroundColor: M3.primaryContainer,
    transform: [{scale: 1.05}],
  },
  dockMenuChipText: {
    color: M3.onSurface,
    fontSize: 14,
    fontWeight: '600',
  },
});

