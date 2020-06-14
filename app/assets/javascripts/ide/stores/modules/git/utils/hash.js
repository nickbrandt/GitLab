/* eslint-disable import/no-extraneous-dependencies */
/* eslint-disable import/prefer-default-export */
import crypto from 'crypto';

export const hash = val => {
  return crypto
    .createHash('sha256')
    .update(val, 'utf8')
    .digest('hex');
};
