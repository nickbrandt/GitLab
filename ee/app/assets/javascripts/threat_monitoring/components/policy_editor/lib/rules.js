import {
  RuleTypeEndpoint,
  RuleTypeEntity,
  RuleTypeCIDR,
  RuleTypeFQDN,
  RuleDirectionInbound,
  PortMatchModeAny,
} from '../constants';

/*
 Return kubernetes specification object that is shared by all rule types.
*/
function commonSpec({ portMatchMode, ports }) {
  if (portMatchMode === PortMatchModeAny) return {};

  const portSelectors = ports.split(/\s/).reduce((acc, item) => {
    const [port, protocol = 'tcp'] = item.split('/');
    const portNumber = parseInt(port, 10);
    if (Number.isNaN(portNumber)) return acc;

    acc.push({ port, protocol: protocol.trim().toUpperCase() });
    return acc;
  }, []);

  return { toPorts: [{ ports: portSelectors }] };
}

/*
 Return kubernetes specification object for an endpoint rule.
*/
function ruleEndpointSpec({ direction, matchLabels }) {
  const matchSelector = matchLabels.split(/\s/).reduce((acc, item) => {
    const [key, value = ''] = item.split(':');
    if (key.length === 0) return acc;

    acc[key] = value.trim();
    return acc;
  }, {});

  if (Object.keys(matchSelector).length === 0) return {};

  return {
    [direction === RuleDirectionInbound ? 'fromEndpoints' : 'toEndpoints']: [
      {
        matchLabels: matchSelector,
      },
    ],
  };
}

/*
  Return kubernetes specification object for an entity rule.
*/
function ruleEntitySpec({ direction, entities }) {
  if (entities.length === 0) return {};

  return {
    [direction === RuleDirectionInbound ? 'fromEntities' : 'toEntities']: entities,
  };
}

/*
  Return kubernetes specification object for a cidr rule.
*/
function ruleCIDRSpec({ direction, cidr }) {
  const cidrList = cidr.length === 0 ? [] : cidr.split(/\s/);
  if (cidrList.length === 0) return {};

  return {
    [direction === RuleDirectionInbound ? 'fromCIDR' : 'toCIDR']: cidrList,
  };
}

/*
  Return kubernetes specification object for a fqdn rule.
*/
function ruleFQDNSpec({ direction, fqdn }) {
  if (direction === RuleDirectionInbound) return {};

  const fqdnList = fqdn.length === 0 ? [] : fqdn.split(/\s/);
  if (fqdnList.length === 0) return {};

  return {
    toFQDNs: fqdnList.map(item => ({ matchName: item })),
  };
}

/*
  Construct a new rule object of the given ruleType.
  oldRule: initialize common rule fields using existing rule.
*/
export function buildRule(ruleType = RuleTypeEndpoint, oldRule) {
  const direction = oldRule?.direction || RuleDirectionInbound;
  const portMatchMode = oldRule?.portMatchMode || PortMatchModeAny;
  const ports = oldRule?.ports || '';
  const commons = { ruleType, direction, portMatchMode, ports };

  switch (ruleType) {
    case RuleTypeEntity:
      return { ...commons, entities: [] };
    case RuleTypeCIDR:
      return { ...commons, cidr: '' };
    case RuleTypeFQDN:
      return { ...commons, fqdn: '' };
    default:
      return { ...commons, matchLabels: '' };
  }
}

/*
 Return rule's kubernetes specification object
*/
export function ruleSpec(rule) {
  const commons = commonSpec(rule);
  switch (rule.ruleType) {
    case RuleTypeEntity:
      return { ...commons, ...ruleEntitySpec(rule) };
    case RuleTypeCIDR:
      return { ...commons, ...ruleCIDRSpec(rule) };
    case RuleTypeFQDN:
      return { ...commons, ...ruleFQDNSpec(rule) };
    default:
      return { ...commons, ...ruleEndpointSpec(rule) };
  }
}
