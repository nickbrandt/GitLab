import ipaddr from 'ipaddr.js';
import validateIpAddress from 'ee/validators/ip_address';

describe('validateIpAddress', () => {
  describe('when IP address is in valid CIDR format', () => {
    it('returns true', () => {
      ipaddr.parseCIDR = jest.fn(() => [
        {
          octets: [192, 168, 0, 0],
        },
        24,
      ]);

      expect(validateIpAddress('192.168.0.0/24')).toBe(true);
    });
  });

  describe('when IP address is not in valid CIDR format', () => {
    it('calls `ipaddr.isValid`', () => {
      ipaddr.parseCIDR = jest.fn(() => {
        throw new Error();
      });

      ipaddr.isValid = jest.fn();

      validateIpAddress('192.168.0.0');

      expect(ipaddr.isValid).toHaveBeenCalledWith('192.168.0.0');
    });
  });
});
