/**
 * Headless boot task: bring Clean Home shell stack back after reboot / install.
 * Must not import UI modules (headless Hermes runtime).
 */
import CleanHomeShell from '../turbo-modules/CleanHomeShell';

export default async function doEnsureBootTask(): Promise<void> {
  try {
    // Idempotent: starts missing daemons; launches Clean Home unless amazon_mode.
    const result = await CleanHomeShell.bootOnce(false);
    console.log('[cleanhome-boot]', result);
  } catch (err) {
    // Never reject: Task Manager treats reject as stuck RUNNING.
    console.error('[cleanhome-boot] failed', err);
  }
}
