import { normalizeData as normalizeDataFOSS } from '~/repository/utils/commit';

// eslint-disable-next-line import/prefer-default-export
export function normalizeData(data, path) {
  return normalizeDataFOSS(data, path, d => ({
    lockLabel: d.lock_label,
  }));
}
