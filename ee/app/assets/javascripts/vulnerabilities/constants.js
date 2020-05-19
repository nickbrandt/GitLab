import { s__ } from '~/locale';

export const VULNERABILITY_STATE_OBJECTS = {
  dismissed: {
    action: 'dismiss',
    state: 'dismissed',
    statusBoxStyle: 'upcoming',
    displayName: s__('VulnerabilityManagement|Dismiss'),
    description: s__('VulnerabilityManagement|Will not fix or a false-positive'),
  },
  confirmed: {
    action: 'confirm',
    state: 'confirmed',
    statusBoxStyle: 'closed',
    displayName: s__('VulnerabilityManagement|Confirm'),
    description: s__('VulnerabilityManagement|A true-positive and will fix'),
  },
  resolved: {
    action: 'resolve',
    state: 'resolved',
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
    tagline: s__('ciReport|Investigate this vulnerability by creating an issue'),
    action: 'createIssue',
  },
  mergeRequestCreation: {
    name: s__('ciReport|Resolve with merge request'),
    tagline: s__('ciReport|Automatically apply the patch in a new branch'),
    action: 'createMergeRequest',
  },
  patchDownload: {
    name: s__('ciReport|Download patch to resolve'),
    tagline: s__('ciReport|Download the patch to apply it manually'),
    action: 'downloadPatch',
  },
};

export const FEEDBACK_TYPES = {
  ISSUE: 'issue',
  MERGE_REQUEST: 'merge_request',
};
