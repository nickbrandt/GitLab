import { safeLoad } from 'js-yaml';
import { buildRule } from './rules';
import {
  DisabledByLabel,
  EndpointMatchModeAny,
  EndpointMatchModeLabel,
  RuleDirectionInbound,
  RuleDirectionOutbound,
  PortMatchModeAny,
  PortMatchModePortProtocol,
  RuleTypeEndpoint,
  RuleTypeEntity,
  RuleTypeCIDR,
  RuleTypeFQDN,
} from '../constants';

const rulesFunc = {
  [RuleTypeEndpoint](items) {
    const labels = items
      .reduce(
        (acc, { matchLabels }) =>
          acc.concat(Object.keys(matchLabels).map(key => `${key}:${matchLabels[key]}`)),
        [],
      )
      .join(' ');
    return { matchLabels: labels };
  },
  [RuleTypeEntity](entities) {
    return { entities };
  },
  [RuleTypeCIDR](items) {
    const cidr = items.join(' ');
    return { cidr };
  },
  [RuleTypeFQDN](items) {
    const fqdn = items.map(({ matchName }) => matchName).join(' ');
    return { fqdn };
  },
};

/*
  Parse yaml rule into an object expected by the policy editor.
*/
function parseRule(item, direction) {
  let ruleItem;
  let ruleType;

  if (item.fromEntities || item.toEntities) {
    ruleType = RuleTypeEntity;
    ruleItem = item.fromEntities || item.toEntities;
  } else if (item.fromCIDR || item.toCIDR) {
    ruleType = RuleTypeCIDR;
    ruleItem = item.fromCIDR || item.toCIDR;
  } else if (item.toFQDNs) {
    ruleType = RuleTypeFQDN;
    ruleItem = item.toFQDNs;
  } else {
    ruleItem = item.fromEndpoints || item.toEndpoints || [];
    ruleType = RuleTypeEndpoint;
  }

  let portMatchMode = PortMatchModeAny;
  let portList = [];
  if (item.toPorts?.length > 0) {
    portMatchMode = PortMatchModePortProtocol;
    portList = item.toPorts.reduce(
      (acc, { ports }) =>
        acc.concat(ports.map(({ port, protocol = 'TCP' }) => `${port}/${protocol.toLowerCase()}`)),
      [],
    );
  }

  return {
    ...buildRule(ruleType, {
      direction,
      portMatchMode,
      ports: portList.join(' '),
    }),
    ...rulesFunc[ruleType](ruleItem),
  };
}

/*
  Construct a policy object expected by the policy editor from a yaml manifest
*/
export default function fromYaml(manifest) {
  const { metadata, spec } = safeLoad(manifest, { json: true });
  const { endpointSelector = {}, ingress = [], egress = [] } = spec;
  const matchLabels = endpointSelector.matchLabels || {};

  const endpointLabels = Object.keys(matchLabels).reduce((acc, key) => {
    if (key === DisabledByLabel) return acc;
    acc.push(`${key}:${matchLabels[key]}`);
    return acc;
  }, []);

  const rules = []
    .concat(
      ingress.map(item => parseRule(item, RuleDirectionInbound)),
      egress.map(item => parseRule(item, RuleDirectionOutbound)),
    )
    .filter(rule => Boolean(rule));

  return {
    name: metadata.name,
    description: spec.description,
    isEnabled: !Object.keys(matchLabels).includes(DisabledByLabel),
    endpointMatchMode: endpointLabels.length > 0 ? EndpointMatchModeLabel : EndpointMatchModeAny,
    endpointLabels: endpointLabels.join(' '),
    rules,
  };
}
