import { TrackingCategories } from './constants';

// eslint-disable-next-line import/prefer-default-export
export const packageTypeToTrackCategory = type =>
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  `UI::${TrackingCategories[type]}`;
