import { safeDump } from 'js-yaml';
import { EndpointMatchModeAny } from '../constants';
import { ruleSpec } from './rules';

/*
 Convert enpdoint labels provided as a string into a kubernetes selector.
 Expected endpointLabels in format "one two:three"
*/
function endpointSelector({ endpointMatchMode, endpointLabels }) {
  if (endpointMatchMode === EndpointMatchModeAny) return {};

  return endpointLabels.split(/\s/).reduce((acc, item) => {
    const [key, value = ''] = item.split(':');
    if (key.length === 0) return acc;

    acc[key] = value.trim();
    return acc;
  }, {});
}

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
