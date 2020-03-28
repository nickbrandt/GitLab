/* eslint-disable @gitlab/require-i18n-strings */

/*
 * Endpoint still returns 'approved' & 'blacklisted'
 * even though we adopted 'allowed' & 'denied' in the UI
 */
export const LICENSE_APPROVAL_STATUS = {
  ALLOWED: 'approved',
  DENIED: 'blacklisted',
};

export const LICENSE_APPROVAL_ACTION = {
  ALLOW: 'allow',
  DENY: 'deny',
};

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
