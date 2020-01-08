import { __ } from '~/locale';

export const defaultTimeWindow = 'thirtyMinutes';

export const timeWindows = {
  thirtyMinutes: {
    label: __('1 hour'),
    seconds: 60 * 60,
  },
  threeHours: {
    label: __('4 hours'),
    seconds: 60 * 60 * 4,
  },
  oneDay: {
    label: __('1 day'),
    seconds: 60 * 60 * 24,
  },
  twoDays: {
    label: __('2 days'),
    seconds: 60 * 60 * 24 * 3,
  },
  pastWeek: {
    label: __('Past week'),
    seconds: 60 * 60 * 24 * 7,
  },
  pastMonth: {
    label: __('Past month'),
    seconds: 60 * 60 * 24 * 30,
  },
};
