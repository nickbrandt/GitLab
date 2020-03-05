import { __ } from '~/locale';

export const healthStatus = {
  ON_TRACK: 'onTrack',
  NEEDS_ATTENTION: 'needsAttention',
  AT_RISK: 'atRisk',
};

export const healthStatusColorMap = {
  [healthStatus.ON_TRACK]: 'text-success',
  [healthStatus.NEEDS_ATTENTION]: 'text-warning',
  [healthStatus.AT_RISK]: 'text-danger',
};

export const healthStatusTextMap = {
  [healthStatus.ON_TRACK]: __('On track'),
  [healthStatus.NEEDS_ATTENTION]: __('Needs attention'),
  [healthStatus.AT_RISK]: __('At risk'),
};
