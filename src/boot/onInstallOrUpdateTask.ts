/**
 * Runs after vpkg install/update. Schedules the durable boot task and starts services once.
 * Must not import UI modules (headless Hermes runtime).
 */
import CleanHomeShell from '../turbo-modules/CleanHomeShell';

export default async function doOnInstallOrUpdateTask(): Promise<void> {
  try {
    const result = await CleanHomeShell.bootOnce(false);
    console.log('[cleanhome-onInstall]', result);
  } catch (err) {
    console.error('[cleanhome-onInstall] failed', err);
  }
}
