import { s__, __ } from '~/locale';

export const INTEGRATION_VIEW_CONFIGS = {
  sourcegraph: {
    title: s__('Preferences|Sourcegraph'),
    label: s__('Preferences|Enable integrated code intelligence on code views'),
    formName: 'sourcegraph_enabled',
  },
  gitpod: {
    title: s__('Preferences|Gitpod'),
    label: s__('Preferences|Enable Gitpod integration'),
    formName: 'gitpod_enabled',
  },
};

export const i18n = {
  saveChanges: __('Save changes'),
  defaultSuccess: __('Preferences saved.'),
  defaultError: s__('Preferences|Failed to save preferences.'),
  localization: s__('Preferences|Localization'),
  localizationDescription: s__('Preferences|Customize language and region related settings.'),
  learnMore: s__('Preferences|Learn more'),
  language: s__('Preferences|Language'),
  experimentalDescription: s__(
    'Preferences|This feature is experimental and translations are not complete yet',
  ),
  firstDayOfTheWeek: s__('Preferences|First day of the week'),
  timePreferences: s__('Preferences|Time preferences'),
  timePreferencesDescription: s__(
    'Preferences|These settings will update how dates and times are displayed for you.',
  ),
  timeFormat: s__('Preferences|Time format'),
  timeFormatLabel: s__('Preferences|Display time in 24-hour format'),
  relativeTime: s__('Preferences|Time display'),
  relativeTimeLabel: s__('Preferences|Use relative times'),
  relativeTimeHelpText: s__('Preferences|For example: 30 mins ago.'),
  integrations: s__('Preferences|Integrations'),
  integrationsDescription: s__('Preferences|Customize integrations with third party services.'),
};
