import NativeCleanHomeShell from './NativeCleanHomeShell';

const BOOT_COMPONENT = 'com.cleanhome.launcher.boot';

class CleanHomeShell {
  ensureServices(noLaunch = true): Promise<string> {
    return NativeCleanHomeShell.ensureServices(noLaunch ? 1 : 0);
  }

  scheduleBootTask(): Promise<string> {
    return NativeCleanHomeShell.scheduleBootTask();
  }

  /** Prefer this from UI / install / headless boot entrypoints. */
  bootOnce(noLaunch = true): Promise<string> {
    return NativeCleanHomeShell.bootOnce(noLaunch ? 1 : 0);
  }

  get bootComponentId(): string {
    return BOOT_COMPONENT;
  }
}

export default new CleanHomeShell();
