import { gray700, orange400 } from '@gitlab/ui/scss_to_js/scss_variables';
import { s__ } from '~/locale';

export const TOTAL_REQUESTS = s__('ThreatMonitoring|Total Requests');
export const ANOMALOUS_REQUESTS = s__('ThreatMonitoring|Anomalous Requests');
export const TIME = s__('ThreatMonitoring|Time');
export const REQUESTS = s__('ThreatMonitoring|Requests');
export const NO_ENVIRONMENT_TITLE = s__('ThreatMonitoring|No environments detected');
export const EMPTY_STATE_DESCRIPTION = s__(
  `ThreatMonitoring|To view this data, ensure you have configured an environment
    for this project and that at least one threat monitoring feature is enabled. %{linkStart}More information%{linkEnd}`,
);

export const COLORS = {
  nominal: gray700,
  anomalous: orange400,
};

// Reuse existing definitions rather than defining them again here,
// otherwise they could get out of sync.
// See https://gitlab.com/gitlab-org/gitlab-ui/issues/554.
export { dateFormats as DATE_FORMATS } from '~/analytics/shared/constants';

export const POLICY_KINDS = {
  ciliumNetwork: 'CiliumNetworkPolicy',
  scanExecution: 'scanner_profile',
};
