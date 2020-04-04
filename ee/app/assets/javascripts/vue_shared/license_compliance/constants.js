import { __, s__ } from '~/locale';

import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/reports/constants';

/*
 * Legacy endpoint still returns 'approved' & 'blacklisted'
 * even though we adopted 'allowed' & 'denied' in the UI
 */
export const LICENSE_APPROVAL_STATUS = {
  ALLOWED: 'approved',
  DENIED: 'blacklisted',
};

/*
 * New project licenses endpoint returns 'allowed' & 'denied'
 */
export const LICENSE_APPROVAL_CLASSIFICATION = {
  ALLOWED: 'allowed',
  DENIED: 'denied',
};

export const LICENSE_APPROVAL_ACTION = {
  ALLOW: 'allow',
  DENY: 'deny',
};

/* eslint-disable @gitlab/require-i18n-strings */
export const KNOWN_LICENSES = [
  'AGPL-1.0',
  'AGPL-3.0',
  'Apache 2.0',
  'Artistic-2.0',
  'BSD',
  'CC0 1.0 Universal',
  'CDDL-1.0',
  'CDDL-1.1',
  'EPL-1.0',
  'EPL-2.0',
  'GPLv2',
  'GPLv3',
  'ISC',
  'LGPL',
  'LGPL-2.1',
  'MIT',
  'Mozilla Public License 2.0',
  'MS-PL',
  'MS-RL',
  'New BSD',
  'Python Software Foundation License',
  'ruby',
  'Simplified BSD',
  'WTFPL',
  'Zlib',
];
/* eslint-enable @gitlab/require-i18n-strings */

export const REPORT_GROUPS = [
  {
    name: s__('LicenseManagement|Denied'),
    description: __("Out-of-compliance with this project's policies and should be removed"),
    status: STATUS_FAILED,
  },
  {
    name: s__('LicenseManagement|Uncategorized'),
    description: __('No policy matches this license'),
    status: STATUS_NEUTRAL,
  },
  {
    name: s__('LicenseManagement|Allowed'),
    description: __('Acceptable for use in this project'),
    status: STATUS_SUCCESS,
  },
];
