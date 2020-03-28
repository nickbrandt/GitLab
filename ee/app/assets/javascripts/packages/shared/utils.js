import { TrackingCategories } from './constants';

export const packageTypeToTrackCategory = type =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `UI::${TrackingCategories[type]}`;

export const beautifyPath = path => (path ? path.split('/').join(' / ') : '');
