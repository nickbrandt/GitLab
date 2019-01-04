import { s__ } from '~/locale';

export const SEVERITIES = {
  critical: 'Critical',
  high: 'High',
  medium: 'Medium',
  low: 'Low',
  unknown: 'Unknown',
  experimental: 'Experimental',
  ignore: 'Ignore',
  undefined: 'Undefined',
};

export const REPORT_TYPES = {
  sast: s__('ciReport|SAST'),
  dependencyScanning: s__('ciReport|Dependency Scanning'),
};
