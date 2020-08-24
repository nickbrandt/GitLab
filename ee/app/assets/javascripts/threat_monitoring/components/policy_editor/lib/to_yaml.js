import { safeDump } from 'js-yaml';
import { ruleSpec } from './rules';
import { labelSelector } from './utils';
import { EndpointMatchModeAny, DisabledByLabel } from '../constants';

/*
 Return kubernetes resource specification object for a policy.
*/
function spec({ description, rules, isEnabled, endpointMatchMode, endpointLabels }) {
  const matchLabels =
    endpointMatchMode === EndpointMatchModeAny ? {} : labelSelector(endpointLabels);
  const policySpec = {};

  if (description?.length > 0) {
    policySpec.description = description;
  }

  policySpec.endpointSelector = Object.keys(matchLabels).length > 0 ? { matchLabels } : {};
  rules.forEach(rule => {
    const { direction } = rule;
    if (!policySpec[direction]) policySpec[direction] = [];

    policySpec[direction].push(ruleSpec(rule));
  });

  if (!isEnabled) {
    policySpec.endpointSelector.matchLabels = {
      ...policySpec.endpointSelector.matchLabels,
      [DisabledByLabel]: 'gitlab',
    };
  }

  return policySpec;
}

/*
 Return yaml representation of a policy.
*/
export default function toYaml(policy) {
  const { name } = policy;

  const policySpec = {
    apiVersion: 'cilium.io/v2',
    kind: 'CiliumNetworkPolicy',
    metadata: { name },
    spec: spec(policy),
  };

  return safeDump(policySpec, { noArrayIndent: true });
}
