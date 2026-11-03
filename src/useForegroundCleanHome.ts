import {useEffect, useRef} from 'react';
import {useKeplerAppStateManager} from '@amazon-devices/react-native-kepler';
import {bridgeFetchFast} from './bridge';

const RESUME_COOLDOWN_MS = 4000;

/** Clear amazon_mode when Clean Home is focused (Amazon apps grid / Home return). */
export function useForegroundCleanHome(): void {
  const appState = useKeplerAppStateManager();
  const lastResumeAt = useRef(0);

  useEffect(() => {
    let alive = true;

    const resumeDefault = () => {
      if (!alive) {
        return;
      }
      const now = Date.now();
      if (now - lastResumeAt.current < RESUME_COOLDOWN_MS) {
        return;
      }
      lastResumeAt.current = now;
      // Only resume when Clean is actually the focused/active surface.
      try {
        if (appState.getCurrentState() !== 'active') {
          return;
        }
      } catch {
        // continue
      }
      bridgeFetchFast('/resume-default').catch(() => {});
      bridgeFetchFast('/start-services?noLaunch=1').catch(() => {});
    };

    // Wait for UI to settle — early bridge/launch races were crashing the process.
    const bootTimer = setTimeout(resumeDefault, 2500);

    let subFocus: {remove: () => void} | null = null;
    let subChange: {remove: () => void} | null = null;
    try {
      subFocus = appState.addEventListener('focus', resumeDefault);
      subChange = appState.addEventListener('change', state => {
        if (state === 'active') {
          resumeDefault();
        }
      });
    } catch {
      // optional
    }

    return () => {
      alive = false;
      clearTimeout(bootTimer);
      subFocus?.remove();
      subChange?.remove();
    };
  }, [appState]);
}
