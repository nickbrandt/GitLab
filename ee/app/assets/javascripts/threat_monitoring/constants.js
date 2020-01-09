import { __ } from '~/locale';

export const INVALID_CURRENT_ENVIRONMENT_NAME = '–';

const INTERVALS = {
  minute: 'minute',
  hour: 'hour',
  day: 'day',
};

export const TIME_WINDOWS = {
  thirtyMinutes: {
    name: __('30 minutes'),
    durationInMilliseconds: 30 * 60 * 1000,
    interval: INTERVALS.minute,
  },
  oneHour: {
    name: __('1 hour'),
    durationInMilliseconds: 60 * 60 * 1000,
    interval: INTERVALS.minute,
  },
  twentyFourHours: {
    name: __('24 hours'),
    durationInMilliseconds: 24 * 60 * 60 * 1000,
    interval: INTERVALS.hour,
  },
  sevenDays: {
    name: __('7 days'),
    durationInMilliseconds: 7 * 24 * 60 * 60 * 1000,
    interval: INTERVALS.hour,
  },
  thirtyDays: {
    name: __('30 days'),
    durationInMilliseconds: 30 * 24 * 60 * 60 * 1000,
    interval: INTERVALS.day,
  },
};

export const DEFAULT_TIME_WINDOW = 'thirtyDays';
