import { TrackingCategories } from './constants';

export const packageTypeToTrackCategory = type =>
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  `UI::${TrackingCategories[type]}`;

export const beautifyPath = path => (path ? path.split('/').join(' / ') : '');
