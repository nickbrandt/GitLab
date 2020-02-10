import { s__ } from '~/locale';

export const SEVERITY_LEVELS = {
  critical: s__('severity|Critical'),
  high: s__('severity|High'),
  medium: s__('severity|Medium'),
  low: s__('severity|Low'),
  unknown: s__('severity|Unknown'),
  info: s__('severity|Info'),
  undefined: s__('severity|Undefined'),
};

export const REPORT_TYPES = {
  container_scanning: s__('ciReport|Container Scanning'),
  dast: s__('ciReport|DAST'),
  dependency_scanning: s__('ciReport|Dependency Scanning'),
  sast: s__('ciReport|SAST'),
};

export const ALL = 'all';
export const BASE_FILTERS = {
  severity: {
    name: s__('ciReport|All severities'),
    id: ALL,
  },
  report_type: {
    name: s__('ciReport|All report types'),
    id: ALL,
  },
  project_id: {
    name: s__('ciReport|All projects'),
    id: ALL,
  },
};
