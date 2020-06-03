import { sample } from 'lodash';
import { AVAILABLE_TOKEN_TYPES } from 'ee/audit_events/constants';
import { availableTokensValidator } from 'ee/audit_events/validators';

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
