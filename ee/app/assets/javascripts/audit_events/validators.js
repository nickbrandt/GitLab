import { AVAILABLE_TOKEN_TYPES } from './constants';

export function availableTokensValidator(value) {
  return value.every(type => AVAILABLE_TOKEN_TYPES.includes(type));
}

export default {};
