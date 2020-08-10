import validateIpAddress from 'ee/validators/ip_address';
import { escape } from 'lodash';
import { __, sprintf } from '~/locale';

export default address => {
  // Reject IP addresses that are only integers to match Ruby IPAddr
  // https://github.com/whitequark/ipaddr.js/issues/7#issuecomment-158545695
  if (/^\d+$/.exec(address) || !validateIpAddress(address)) {
    return sprintf(
      __('%{address} is an invalid IP address range'),
      { address: escape(address) },
      false,
    );
  }

  return '';
};
