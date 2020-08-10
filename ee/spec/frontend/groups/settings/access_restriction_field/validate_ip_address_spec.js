import * as validateIpAddress from 'ee/validators/ip_address';
import validateRestrictedIpAddress from 'ee/groups/settings/access_restriction_field/validate_ip_address';

describe('validateRestrictedIpAddress', () => {
  describe('when IP address is only integers', () => {
    it.each`
      address
      ${1}
      ${19}
      ${192}
    `('$address - returns an error message', ({ address }) => {
      expect(validateRestrictedIpAddress(address)).toBe(
        `${address} is an invalid IP address range`,
      );
    });
  });

  describe('when `validateIpAddress` returns false', () => {
    it('returns an error message', () => {
      validateIpAddress.default = jest.fn(() => false);

      expect(validateRestrictedIpAddress('foo bar')).toBe(`foo bar is an invalid IP address range`);
    });
  });

  describe('when IP address is valid', () => {
    it('returns an empty string', () => {
      validateIpAddress.default = jest.fn(() => true);

      expect(validateRestrictedIpAddress('192.168.0.0/24')).toBe('');
    });
  });
});
