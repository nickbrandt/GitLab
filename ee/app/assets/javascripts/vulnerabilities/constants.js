import { s__ } from '~/locale';

// eslint-disable-next-line import/prefer-default-export
export const VULNERABILITY_STATES = {
  dismissed: {
    action: 'dismiss',
    displayName: s__('VulnerabilityManagement|Dismiss'),
    description: s__('VulnerabilityManagement|Will not fix or a false-positive'),
  },
  confirmed: {
    action: 'confirm',
    displayName: s__('VulnerabilityManagement|Confirm'),
    description: s__('VulnerabilityManagement|A true-positive and will fix'),
  },
  resolved: {
    action: 'resolve',
    displayName: s__('VulnerabilityManagement|Resolved'),
    description: s__('VulnerabilityManagement|Verified as fixed or mitigated'),
  },
};
