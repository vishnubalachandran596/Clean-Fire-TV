import {useEffect, useRef} from 'react';
import CleanHomeShell from './turbo-modules/CleanHomeShell';

/**
 * On interactive launch, ensure /data daemons are up and (re)schedule the
 * durable headless boot task so reboot does not require Mac boost-firetv.sh.
 */
export function useBootServices(): void {
  const ran = useRef(false);

  useEffect(() => {
    if (ran.current) {
      return;
    }
    ran.current = true;
    // noLaunch: interactive UI is already foregrounding Clean Home.
    CleanHomeShell.bootOnce(true).catch(() => {
      // Native module or /data scripts may be missing on first sideload.
    });
  }, []);
}
