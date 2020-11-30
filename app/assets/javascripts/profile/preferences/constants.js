import { s__ } from '~/locale';

export const INTEGRATION_VIEW_CONFIGS = {
  sourcegraph: {
    title: s__('ProfilePreferences|Sourcegraph'),
    label: s__('ProfilePreferences|Enable integrated code intelligence on code views'),
    formName: 'sourcegraph_enabled',
  },
  gitpod: {
    title: s__('ProfilePreferences|Gitpod'),
    label: s__('ProfilePreferences|Enable Gitpod integration'),
    formName: 'gitpod_enabled',
  },
};

export const i18n = {
  localization: s__('ProfilePreferences|Localization'),
  localizationDescription: s__(
    'ProfilePreferences|Customize language and region related settings.',
  ),
  learnMore: s__('ProfilePreferences|Learn more'),
  language: s__('ProfilePreferences|Language'),
  experimentalDescription: s__(
    'ProfilePreferences|This feature is experimental and translations are not complete yet',
  ),
  firstDayOfTheWeek: s__('ProfilePreferences|First day of the week'),
  timePreferences: s__('ProfilePreferences|Time preferences'),
  timePreferencesDescription: s__(
    'ProfilePreferences|These settings will update how dates and times are displayed for you.',
  ),
  timeFormat: s__('ProfilePreferences|Time format'),
  timeFormatLabel: s__('ProfilePreferences|Display time in 24-hour format'),
  relativeTimeLabel: s__('ProfilePreferences|For example: 30 mins ago.'),
  integrations: s__('ProfilePreferences|Integrations'),
  integrationsDescription: s__(
    'ProfilePreferences|Customize integrations with third party services.',
  ),
};
