import CEGetStateKey from '~/vue_merge_request_widget/stores/get_state_key';
import { stateKey } from './state_maps';

export default function(data) {
  if (this.isGeoSecondaryNode) {
    return 'geoSecondaryNode';
  }

  if (data.policy_violation) {
    return stateKey.policyViolation;
  }

  return CEGetStateKey.call(this, data);
}
