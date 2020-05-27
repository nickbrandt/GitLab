import { sample } from 'lodash';
import { AVAILABLE_TOKEN_TYPES } from 'ee/audit_logs/constants';
import { availableTokensValidator } from 'ee/audit_logs/validators';

describe('availableTokensValidator', () => {
  it('returns true when the input contains an available token type', () => {
    const input = [sample(AVAILABLE_TOKEN_TYPES)];
    expect(availableTokensValidator(input)).toEqual(true);
  });
  it('returns false when the input contains an unavailable token type', () => {
    const input = ['InvalidType'];
    expect(availableTokensValidator(input)).toEqual(false);
  });
});
