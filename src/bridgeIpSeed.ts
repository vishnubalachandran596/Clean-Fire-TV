/**
 * Bootstraps the bridge LAN host when loopback fetch is blocked in the app sandbox.
 * Updated by deploy scripts from the stick's current IP — not a permanent DHCP pin.
 * Runtime discovery refreshes every 1s and overrides this when Wi‑Fi changes.
 */
export const BRIDGE_IP_SEED = '0.0.0.0';
