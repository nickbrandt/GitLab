import { EndpointMatchModeAny, PortMatchModeAny } from '../constants';

/*
 Convert enpdoint labels provided as a string into a kubernetes selector.
 Expects endpointLabels in format "one two:three"
*/
export function endpointSelector({ endpointMatchMode, endpointLabels }) {
  if (endpointMatchMode === EndpointMatchModeAny) return {};

  return endpointLabels.split(/\s/).reduce((acc, item) => {
    const [key, value = ''] = item.split(':');
    if (key.length === 0) return acc;

    acc[key] = value.trim();
    return acc;
  }, {});
}

/*
 Convert ports provided as a string into a kubernetes port selectors.
 Expects ports in format "80/tcp 81"
*/
export function portSelectors({ portMatchMode, ports }) {
  if (portMatchMode === PortMatchModeAny) return {};

  return ports.split(/\s/).reduce((acc, item) => {
    const [port, protocol = 'tcp'] = item.split('/');
    const portNumber = parseInt(port, 10);
    if (Number.isNaN(portNumber)) return acc;

    acc.push({ port, protocol: protocol.trim().toUpperCase() });
    return acc;
  }, []);
}

/*
 Convert list of labels provided as a string into a kubernetes endpoint selector.
 Expects matchLabels in format "one two:three"
*/
export function ruleEndpointSelector(matchLabels) {
  return matchLabels.split(/\s/).reduce((acc, item) => {
    const [key, value = ''] = item.split(':');
    if (key.length === 0) return acc;

    acc[key] = value.trim();
    return acc;
  }, {});
}

/*
 Convert list of CIDRs provided as a string into a CIDR list expected by the kubernetes policy.
 Expects cidr in format "0.0.0.0/24 1.1.1.1/32"
*/
export function ruleCIDRList(cidr) {
  return cidr.length === 0 ? [] : cidr.split(/\s/);
}

/*
 Convert list of FQDNs provided as a string into a FQDN list expected be the kubernetes policy.
 Expects fqdn in format "one-service.com another-service.com"
*/
export function ruleFQDNList(fqdn) {
  return fqdn.length === 0 ? [] : fqdn.split(/\s/);
}
