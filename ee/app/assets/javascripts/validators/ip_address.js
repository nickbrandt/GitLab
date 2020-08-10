import ipaddr from 'ipaddr.js';

export default address => {
  try {
    // Checks if Valid IPv4/IPv6 (CIDR) - Throws if not
    return Boolean(ipaddr.parseCIDR(address));
  } catch (e) {
    // Checks if Valid IPv4/IPv6 (Non-CIDR) - Does not Throw
    return ipaddr.isValid(address);
  }
};
