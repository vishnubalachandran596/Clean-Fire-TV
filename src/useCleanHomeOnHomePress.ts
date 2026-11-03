import {useEffect, useRef} from 'react';
import {
  useKeplerAppStateManager,
  type KeplerReconfigureReasonData,
} from '@amazon-devices/react-native-kepler';
import {bridgeFetch} from './bridge';

function isHomePressed(event: unknown): event is KeplerReconfigureReasonData {
  return (
    typeof event === 'object' &&
    event !== null &&
    'reconfigureReason' in event &&
    (event as KeplerReconfigureReasonData).reconfigureReason === 'homePressed'
  );
}

/**
 * Home while Clean is alive (e.g. returning from Amazon HUD): clear amazon_mode.
 * Do not Linking.openURL here — firetv-home + /home-to-clean already foreground Clean;
 * double open + smpl terminate caused Clean↔Amazon loops.
 */
export function useCleanHomeOnHomePress(enabled: boolean): void {
  const appState = useKeplerAppStateManager();
  const busy = useRef(false);

  useEffect(() => {
    if (!enabled) {
      return;
    }

    const goClean = () => {
      if (busy.current) {
        return;
      }
      busy.current = true;
      bridgeFetch('/home-to-clean').catch(() => {});
      setTimeout(() => {
        busy.current = false;
      }, 1500);
    };

    const onReconfigure = (event: unknown) => {
      if (isHomePressed(event)) {
        goClean();
      }
    };

    // Plain listener only — WithReplay can replay a stale homePressed and
    // yank Amazon Home right after /amazon-home without a new Home press.
    const subPlain = appState.addEventListener('reconfigure', onReconfigure);

    return () => {
      subPlain.remove();
    };
  }, [appState, enabled]);
}
