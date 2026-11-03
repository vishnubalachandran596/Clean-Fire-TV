import {AsyncStorage} from '@amazon-devices/react-native-kepler';
import {BRIDGE_IP_SEED} from './bridgeIpSeed';
import type {HomeScreenStats} from './settingsTypes';

const BRIDGE_PORT = 8765;
const HOST_CACHE_KEY = 'cleanhome.bridge.host.v1';
const BRIDGE_TIMEOUT_MS = 4000;
const METRICS_TIMEOUT_MS = 1200;
const LAUNCH_TIMEOUT_MS = 5000;
const HOST_PROBE_MS = 900;
/** Re-resolve LAN IP often — DHCP / Wi‑Fi changes break a stale host. */
const HOST_REFRESH_MS = 1000;

const LOOPBACK_HOSTS = [
  `http://127.0.0.1:${BRIDGE_PORT}`,
  `http://localhost:${BRIDGE_PORT}`,
];

function isLikelyLanSeed(ip: string): boolean {
  const trimmed = (ip || '').trim();
  if (!/^\d{1,3}(?:\.\d{1,3}){3}$/.test(trimmed)) {
    return false;
  }
  // Placeholder / loopback / unspecified — never treat as a reachable bridge host.
  if (
    trimmed === '0.0.0.0' ||
    trimmed === '255.255.255.255' ||
    trimmed.startsWith('127.')
  ) {
    return false;
  }
  return true;
}

let rememberedHost: string | null = isLikelyLanSeed(BRIDGE_IP_SEED)
  ? `http://${BRIDGE_IP_SEED}:${BRIDGE_PORT}`
  : null;
let lastHostRefreshMs = 0;
let refreshInFlight: Promise<void> | null = null;

function hostFromIp(ip: string): string {
  return `http://${ip}:${BRIDGE_PORT}`;
}

function isIpv4(value: string): boolean {
  return /^\d{1,3}(?:\.\d{1,3}){3}$/.test(value);
}

function parseIpFromFib(text: string): string | null {
  const lines = text.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    if (!/host LOCAL/.test(lines[i])) {
      continue;
    }
    for (let j = Math.max(0, i - 2); j < i; j++) {
      const m = lines[j].match(/\|\-\-\s+(\d+\.\d+\.\d+\.\d+)\s*$/);
      if (m && !m[1].startsWith('127.')) {
        return m[1];
      }
    }
  }
  return null;
}

async function readTextFile(
  uri: string,
  timeoutMs: number = 600,
): Promise<string | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(uri, {signal: controller.signal});
    clearTimeout(timer);
    if (!res.ok && res.status !== 0) {
      return null;
    }
    const text = (await res.text()).trim();
    return text || null;
  } catch (_e) {
    clearTimeout(timer);
    return null;
  }
}

async function discoverLanIp(): Promise<string | null> {
  const published = await readTextFile('file:///data/cleanhome.bridge_ip');
  if (published && isIpv4(published.split(/\s+/)[0])) {
    return published.split(/\s+/)[0];
  }
  const fib = await readTextFile('file:///proc/net/fib_trie');
  if (fib) {
    const ip = parseIpFromFib(fib);
    if (ip) {
      return ip;
    }
  }
  if (isIpv4(BRIDGE_IP_SEED)) {
    return BRIDGE_IP_SEED;
  }
  return null;
}

async function loadCachedHost(): Promise<string | null> {
  if (rememberedHost) {
    return rememberedHost;
  }
  try {
    const saved = await AsyncStorage.getItem(HOST_CACHE_KEY);
    if (saved && /^https?:\/\//.test(saved)) {
      rememberedHost = saved;
      return saved;
    }
  } catch (_e) {
    // ignore
  }
  return null;
}

async function rememberHost(host: string): Promise<void> {
  if (rememberedHost === host) {
    return;
  }
  rememberedHost = host;
  try {
    await AsyncStorage.setItem(HOST_CACHE_KEY, host);
  } catch (_e) {
    // ignore
  }
}

/** Seed / update bridge host from a known IPv4 (launch query, metrics payload, etc.). */
export async function setBridgeIp(ip: string): Promise<void> {
  const trimmed = ip.trim();
  if (!isIpv4(trimmed)) {
    return;
  }
  await rememberHost(hostFromIp(trimmed));
  lastHostRefreshMs = Date.now();
}

/** Prefer fresh LAN IP, then cache, seed, loopback last. */
async function resolveBridgeHosts(): Promise<string[]> {
  const hosts: string[] = [];
  const seen = new Set<string>();
  const add = (host: string | null | undefined) => {
    if (!host || seen.has(host)) {
      return;
    }
    seen.add(host);
    hosts.push(host);
  };

  const lanIp = await discoverLanIp();
  if (lanIp) {
    add(hostFromIp(lanIp));
  }
  add(await loadCachedHost());
  if (isIpv4(BRIDGE_IP_SEED)) {
    add(hostFromIp(BRIDGE_IP_SEED));
  }
  for (const h of LOOPBACK_HOSTS) {
    add(h);
  }
  return hosts;
}

async function probeHost(host: string): Promise<boolean> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), HOST_PROBE_MS);
  try {
    const res = await fetch(`${host}/ping`, {signal: controller.signal});
    clearTimeout(timer);
    return res.status >= 200 && res.status < 500;
  } catch (_e) {
    clearTimeout(timer);
    return false;
  }
}

export async function refreshBridgeHost(): Promise<void> {
  const now = Date.now();
  if (refreshInFlight) {
    return refreshInFlight;
  }
  if (now - lastHostRefreshMs < HOST_REFRESH_MS && rememberedHost) {
    // Still re-check published IP so Wi‑Fi changes are picked up quickly.
  }
  refreshInFlight = (async () => {
    try {
      const lanIp = await discoverLanIp();
      if (lanIp) {
        const host = hostFromIp(lanIp);
        if (await probeHost(host)) {
          await rememberHost(host);
        } else if (!rememberedHost) {
          await rememberHost(host);
        } else if (rememberedHost !== host) {
          // IP changed — switch even if probe flaps once.
          await rememberHost(host);
        }
      }
      lastHostRefreshMs = Date.now();
    } finally {
      refreshInFlight = null;
    }
  })();
  return refreshInFlight;
}

/** Call once from UI — refreshes LAN bridge host every second. */
export function startBridgeHostWatcher(): () => void {
  let stopped = false;
  const tick = () => {
    if (stopped) {
      return;
    }
    refreshBridgeHost().catch(() => {});
  };
  tick();
  const id = setInterval(tick, HOST_REFRESH_MS);
  return () => {
    stopped = true;
    clearInterval(id);
  };
}

/** Eager bridge warm at launcher boot so first dock OK skips host discovery. */
export function warmupBridge(): void {
  if (isLikelyLanSeed(BRIDGE_IP_SEED) && !rememberedHost) {
    rememberedHost = hostFromIp(BRIDGE_IP_SEED);
  }
  void loadCachedHost().then(host => {
    if (host && !rememberedHost) {
      rememberedHost = host;
    }
  });
  void refreshBridgeHost().catch(() => {});
}

type BridgeFetchOpts = {
  /** Skip awaiting LAN probe — use for /launch so OK isn't delayed ~1s. */
  skipHostRefresh?: boolean;
};

async function bridgeFetchWithTimeout(
  path: string,
  timeoutMs: number,
  opts?: BridgeFetchOpts,
): Promise<Response | null> {
  if (opts?.skipHostRefresh) {
    void refreshBridgeHost();
  } else {
    await refreshBridgeHost();
  }

  const hosts: string[] = [];
  const seen = new Set<string>();
  const add = (host: string | null | undefined) => {
    if (!host || seen.has(host)) {
      return;
    }
    seen.add(host);
    hosts.push(host);
  };

  add(rememberedHost);
  if (isLikelyLanSeed(BRIDGE_IP_SEED)) {
    add(hostFromIp(BRIDGE_IP_SEED));
  }
  if (!opts?.skipHostRefresh) {
    for (const h of await resolveBridgeHosts()) {
      add(h);
    }
  } else if (!rememberedHost) {
    // Only touch AsyncStorage when seed/memory miss — keep OK→launch tight.
    add(await loadCachedHost());
    for (const h of LOOPBACK_HOSTS) {
      add(h);
    }
  }

  for (const host of hosts) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const res = await fetch(`${host}${path}`, {signal: controller.signal});
      clearTimeout(timer);
      if (res.status >= 200 && res.status < 500) {
        await rememberHost(host);
        return res;
      }
    } catch (_e) {
      clearTimeout(timer);
    }
  }
  return null;
}

export async function bridgeFetch(path: string): Promise<Response | null> {
  return bridgeFetchWithTimeout(path, BRIDGE_TIMEOUT_MS);
}

/** Hot-path bridge call (dock OK / Amazon) — never awaits host probe. */
export async function bridgeFetchFast(
  path: string,
  timeoutMs: number = BRIDGE_TIMEOUT_MS,
): Promise<Response | null> {
  return bridgeFetchWithTimeout(path, timeoutMs, {skipHostRefresh: true});
}

async function readJson<T>(res: Response): Promise<T | null> {
  try {
    const text = await res.text();
    if (!text.trim()) {
      return null;
    }
    return JSON.parse(text) as T;
  } catch (_e) {
    return null;
  }
}

/**
 * Metrics only — fast RAM/ROM/speed cache.
 * Never hits /screen-stats (pings) so it cannot block /launch on inetd.
 */
export async function fetchHomeStatsPassive(): Promise<HomeScreenStats | null> {
  const res = await bridgeFetchWithTimeout(
    '/screen-stats-fast',
    METRICS_TIMEOUT_MS,
  );
  if (!res) {
    return null;
  }
  const data = await readJson<HomeScreenStats & {ip?: string}>(res);
  if (data?.ip && isIpv4(data.ip)) {
    await rememberHost(hostFromIp(data.ip));
  }
  if (data?.ok !== false && typeof data?.freeMb === 'number') {
    return data;
  }
  return null;
}

export async function bridgeFetchWithRetry(path: string): Promise<Response | null> {
  let res = await bridgeFetch(path);
  if (res) {
    return res;
  }
  await bridgeFetch('/start-services?noLaunch=1');
  return bridgeFetch(path);
}

export async function bridgeLaunch(component: string): Promise<boolean> {
  const res = await bridgeFetchFast(
    `/launch/${encodeURIComponent(component)}`,
    LAUNCH_TIMEOUT_MS,
  );
  if (!res) {
    return false;
  }
  const data = await readJson<{ok?: boolean}>(res);
  return data?.ok === true;
}

/**
 * Kick /launch without waiting for the HTTP body — used with Linking.openURL
 * so the stick starts the app immediately while cooldown is stamped.
 */
export function bridgeLaunchKick(component: string): void {
  const path = `/launch/${encodeURIComponent(component)}`;
  const hosts: string[] = [];
  const seen = new Set<string>();
  const add = (host: string | null | undefined) => {
    if (!host || seen.has(host)) {
      return;
    }
    // Never kick a placeholder host from a bad seed/cache.
    if (/:\/\/0\.0\.0\.0(?::|\/|$)/.test(host)) {
      return;
    }
    seen.add(host);
    hosts.push(host);
  };

  add(rememberedHost);
  if (isLikelyLanSeed(BRIDGE_IP_SEED)) {
    add(hostFromIp(BRIDGE_IP_SEED));
  }
  for (const h of LOOPBACK_HOSTS) {
    add(h);
  }

  if (!hosts.length) {
    void bridgeLaunch(component);
    return;
  }

  // Fire all candidates — first host used to be 0.0.0.0 and returned early,
  // so dock OK never reached the real LAN bridge after reboot.
  for (const host of hosts) {
    void fetch(`${host}${path}`)
      .then(res => {
        if (res.status >= 200 && res.status < 500) {
          void rememberHost(host);
        }
      })
      .catch(() => {});
  }
  void refreshBridgeHost().catch(() => {});
}
