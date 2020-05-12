import { s__ } from '~/locale';

export const VULNERABILITY_STATE_OBJECTS = {
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

export const VULNERABILITY_STATES = {
  detected: s__('VulnerabilityStatusTypes|Detected'),
  confirmed: s__('VulnerabilityStatusTypes|Confirmed'),
  dismissed: s__('VulnerabilityStatusTypes|Dismissed'),
  resolved: s__('VulnerabilityStatusTypes|Resolved'),
};

export const VULNERABILITIES_PER_PAGE = 20;

export const HEADER_ACTION_BUTTONS = {
  issueCreation: {
    name: s__('ciReport|Create issue'),
    action: 'createIssue',
  },
};
