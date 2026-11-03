import type {KeplerTurboModule} from '@amazon-devices/keplerscript-turbomodule-api';
import {TurboModuleRegistry} from '@amazon-devices/keplerscript-turbomodule-api';

/**
 * On-device shell helpers for boot / ensure-services.
 * Optional — native lib may be unlinked; never getEnforcing (that aborts the JS runtime).
 */
export interface Spec extends KeplerTurboModule {
  ensureServices: (noLaunch: number) => Promise<string>;
  scheduleBootTask: () => Promise<string>;
  bootOnce: (noLaunch: number) => Promise<string>;
}

const native = TurboModuleRegistry.get<Spec>('CleanHomeShell');

const stub: Spec = {
  ensureServices: async () => 'stub:no-native',
  scheduleBootTask: async () => 'stub:no-native',
  bootOnce: async () => 'stub:no-native',
  // KeplerTurboModule marker fields unused by our wrappers
} as Spec;

export default native ?? stub;
