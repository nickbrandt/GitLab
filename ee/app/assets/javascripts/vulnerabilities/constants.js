import { s__ } from '~/locale';

// eslint-disable-next-line import/prefer-default-export
export const VULNERABILITY_STATES = {
  dismissed: {
    action: 'dismiss',
    statusBoxStyle: 'upcoming',
    displayName: s__('VulnerabilityManagement|Dismiss'),
    description: s__('VulnerabilityManagement|Will not fix or a false-positive'),
  },
  confirmed: {
    action: 'confirm',
    statusBoxStyle: 'closed',
    displayName: s__('VulnerabilityManagement|Confirm'),
    description: s__('VulnerabilityManagement|A true-positive and will fix'),
  },
  resolved: {
    action: 'resolve',
    statusBoxStyle: 'open',
    displayName: s__('VulnerabilityManagement|Resolved'),
    description: s__('VulnerabilityManagement|Verified as fixed or mitigated'),
  },
};
