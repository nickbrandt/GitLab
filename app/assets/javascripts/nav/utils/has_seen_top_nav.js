import { memoize } from 'lodash';
import AccessorUtilities from '~/lib/utils/accessor';

export const STORAGE_KEY = 'gitlab::nav::has_seen_top_nav';

export const isAvailable = memoize(() => AccessorUtilities.isLocalStorageAccessSafe());

export const hasSeenTopNav = () => {
  if (!isAvailable()) {
    return false;
  }

  const item = localStorage.getItem(STORAGE_KEY);

  return Boolean(item);
};

export const setSeenTopNav = () => {
  if (!isAvailable()) {
    return;
  }

  localStorage.setItem(STORAGE_KEY, '1');
};
