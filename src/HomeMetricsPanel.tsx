import * as React from 'react';
import {useCallback, useEffect, useState} from 'react';
import {View, Text, StyleSheet, InteractionManager} from 'react-native';
import {
  AsyncStorage,
  useKeplerAppStateManager,
} from '@amazon-devices/react-native-kepler';
import {fetchHomeStatsPassive} from './bridge';
import {formatRam, formatSpeed, formatStorage} from './homeMetricsFormat';
import type {HomeScreenStats} from './settingsTypes';

const STATS_CACHE_KEY = 'cleanhome.stats.cache.v1';
const METRICS_START_DELAY_MS = 600;
/** Fast RAM/ROM/speed only — never blocks app launches. */
const METRICS_POLL_ACTIVE_MS = 1000;

function formatDate(d: Date): string {
  const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const MONTHS = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return `${WEEKDAYS[d.getDay()]}, ${MONTHS[d.getMonth()]} ${d.getDate()}`;
}

function formatTime(d: Date): string {
  const h = d.getHours();
  const m = d.getMinutes();
  const hour12 = h % 12 || 12;
  const ampm = h >= 12 ? 'PM' : 'AM';
  return `${hour12}:${m.toString().padStart(2, '0')} ${ampm}`;
}

function HomeMetricsPanelInner({now}: {now: Date}) {
  const [homeStats, setHomeStats] = useState<HomeScreenStats | null>(null);
  const appState = useKeplerAppStateManager();
  const [launcherActive, setLauncherActive] = useState(true);

  useEffect(() => {
    const setActive = (active: boolean) => setLauncherActive(active);
    const sync = () => {
      try {
        setActive(appState.getCurrentState() === 'active');
      } catch {
        setActive(true);
      }
    };
    sync();
    const subChange = appState.addEventListener('change', state => {
      setActive(state === 'active');
    });
    const subFocus = appState.addEventListener('focus', () => setActive(true));
    const subBlur = appState.addEventListener('blur', () => setActive(false));
    return () => {
      subChange.remove();
      subFocus.remove();
      subBlur.remove();
    };
  }, [appState]);

  const applyHomeStats = useCallback((data: HomeScreenStats) => {
    setHomeStats(prev => {
      if (prev && JSON.stringify(prev) === JSON.stringify(data)) {
        return prev;
      }
      AsyncStorage.setItem(STATS_CACHE_KEY, JSON.stringify(data)).catch(
        () => {},
      );
      return data;
    });
  }, []);

  const refreshHomeStats = useCallback(() => {
    InteractionManager.runAfterInteractions(() => {
      fetchHomeStatsPassive()
        .then(data => {
          if (data) {
            applyHomeStats(data);
          }
        })
        .catch(() => {});
    });
  }, [applyHomeStats]);

  useEffect(() => {
    AsyncStorage.getItem(STATS_CACHE_KEY)
      .then(saved => {
        if (!saved) {
          return;
        }
        try {
          setHomeStats(JSON.parse(saved) as HomeScreenStats);
        } catch {
          // ignore corrupt cache
        }
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (!launcherActive) {
      return;
    }
    let metricsTimer: ReturnType<typeof setInterval> | null = null;
    const startTimer = setTimeout(() => {
      refreshHomeStats();
      metricsTimer = setInterval(refreshHomeStats, METRICS_POLL_ACTIVE_MS);
    }, METRICS_START_DELAY_MS);
    return () => {
      clearTimeout(startTimer);
      if (metricsTimer) {
        clearInterval(metricsTimer);
      }
    };
  }, [launcherActive, refreshHomeStats]);

  return (
    <View style={styles.rightHeaderCol} pointerEvents="none">
      <View style={styles.dateTimeBlock}>
        <Text style={styles.dateText}>{formatDate(now)}</Text>
        <Text style={styles.timeText}>{formatTime(now)}</Text>
      </View>
      <View style={styles.statsColumn}>
        <Text style={styles.headerStats} numberOfLines={1}>
          RAM: {formatRam(homeStats?.freeMb, homeStats?.totalMb)}
        </Text>
        <Text style={styles.headerStats} numberOfLines={1}>
          ROM:{' '}
          {formatStorage(homeStats?.storageFreeMb, homeStats?.storageTotalMb)}
        </Text>
        <Text style={styles.headerStats} numberOfLines={1}>
          Speed: {formatSpeed(homeStats)}
        </Text>
      </View>
    </View>
  );
}

export const HomeMetricsPanel = React.memo(HomeMetricsPanelInner);

const styles = StyleSheet.create({
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
});
