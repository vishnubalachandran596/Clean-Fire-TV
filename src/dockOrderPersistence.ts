import {AsyncStorage} from '@amazon-devices/react-native-kepler';
import {bridgeFetch} from './bridge';

export const DOCK_ORDER_STORAGE_KEY = 'cleanhome.icon.order.v1';

function parseOrderJson(raw: string | null | undefined): string[] | null {
  if (!raw?.trim()) {
    return null;
  }
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) {
      return null;
    }
    const ids = parsed.filter(
      (id): id is string => typeof id === 'string' && id.length > 0,
    );
    return ids.length ? ids : null;
  } catch {
    return null;
  }
}

/** Load dock order: device file first (survives reinstall), then AsyncStorage. */
export async function loadDockOrder(): Promise<string[] | null> {
  const res = await bridgeFetch('/dock-order');
  if (res) {
    try {
      const data = (await res.json()) as {ok?: boolean; order?: string[]};
      if (data.ok && Array.isArray(data.order) && data.order.length) {
        const ids = data.order.filter(Boolean);
        if (ids.length) {
          await AsyncStorage.setItem(
            DOCK_ORDER_STORAGE_KEY,
            JSON.stringify(ids),
          ).catch(() => {});
          return ids;
        }
      }
    } catch {
      // fall through
    }
  }

  try {
    const saved = await AsyncStorage.getItem(DOCK_ORDER_STORAGE_KEY);
    return parseOrderJson(saved);
  } catch {
    return null;
  }
}

/** Save to /data (bridge) and AsyncStorage. */
export async function saveDockOrder(ids: string[]): Promise<void> {
  const cleaned = ids.filter(Boolean);
  const payload = JSON.stringify(cleaned);
  await AsyncStorage.setItem(DOCK_ORDER_STORAGE_KEY, payload).catch(() => {});
  await bridgeFetch(
    `/dock-order?order=${encodeURIComponent(payload)}`,
  ).catch(() => {});
}
