import { __ } from '~/locale';

export const healthStatus = {
  ON_TRACK: 'onTrack',
  NEEDS_ATTENTION: 'needsAttention',
  AT_RISK: 'atRisk',
};

export const healthStatusTextMap = {
  [healthStatus.ON_TRACK]: __('On track'),
  [healthStatus.NEEDS_ATTENTION]: __('Needs attention'),
  [healthStatus.AT_RISK]: __('At risk'),
};
