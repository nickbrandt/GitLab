import { normalizeData as normalizeDataFOSS } from '~/repository/utils/commit';

// eslint-disable-next-line import/prefer-default-export
export function normalizeData(data) {
  return normalizeDataFOSS(data, d => ({
    lockLabel: d.lock_label,
  }));
}
