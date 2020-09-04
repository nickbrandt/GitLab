import { s__ } from '~/locale';

export const DAST_SITE_VALIDATION_METHOD_TEXT_FILE = 'DAST_SITE_VALIDATION_METHOD_TEXT_FILE';
export const DAST_SITE_VALIDATION_METHODS = {
  DAST_SITE_VALIDATION_METHOD_TEXT_FILE: {
    value: DAST_SITE_VALIDATION_METHOD_TEXT_FILE,
    text: s__('DastProfiles|Text file validation'),
    i18n: {
      locationStepLabel: s__('DastProfiles|Step 3 - Confirm text file location and validate'),
    },
  },
};
