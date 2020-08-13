import { safeDump } from 'js-yaml';
import { ruleSpec } from './rules';
import { endpointSelector } from './utils';

/*
 Return kubernetes resource specification object for a policy.
*/
function spec(policy) {
  const { description, rules, isEnabled } = policy;
  const matchLabels = endpointSelector(policy);
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
      'network-policy.gitlab.com/disabled_by': 'gitlab',
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
