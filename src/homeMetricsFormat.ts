import type {HomeScreenStats} from './settingsTypes';

export function formatRam(free?: number, total?: number): string {
  if (free == null || total == null) {
    return '—';
  }
  return `${free} / ${total} MB`;
}

export function formatStorage(freeMb?: number, totalMb?: number): string {
  if (totalMb == null || totalMb <= 0) {
    return '—';
  }
  const free = freeMb ?? 0;
  return `${(free / 1024).toFixed(1)} / ${(totalMb / 1024).toFixed(1)} GB`;
}

export function formatSpeed(stats: HomeScreenStats | null): string {
  if (!stats || stats.speedMbps == null) {
    return '…';
  }
  const n = Number(stats.speedMbps);
  if (!Number.isFinite(n) || n <= 0) {
    return '…';
  }
  return `${n.toFixed(1)} Mbps`;
}
