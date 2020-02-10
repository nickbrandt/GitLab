import { s__ } from '~/locale';

export const SEVERITY_LEVELS = {
  critical: s__('severity|Critical'),
  high: s__('severity|High'),
  medium: s__('severity|Medium'),
  low: s__('severity|Low'),
  unknown: s__('severity|Unknown'),
  info: s__('severity|Info'),
  undefined: s__('severity|Undefined'),
  none: s__('severity|None'),
};

export const REPORT_TYPES = {
  container_scanning: s__('ciReport|Container Scanning'),
  dast: s__('ciReport|DAST'),
  dependency_scanning: s__('ciReport|Dependency Scanning'),
  sast: s__('ciReport|SAST'),
};

export const DASHBOARD_TYPES = {
  PROJECT: 'project',
  PIPELINE: 'pipeline',
  GROUP: 'group',
  INSTANCE: 'instance',
};
