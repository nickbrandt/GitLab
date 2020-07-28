import httpStatusCodes from '~/lib/utils/http_status';

export const CRITICAL = 'critical';
export const HIGH = 'high';
export const MEDIUM = 'medium';
export const LOW = 'low';
export const INFO = 'info';
export const UNKNOWN = 'unknown';
export const SEVERITIES = [CRITICAL, HIGH, MEDIUM, LOW, INFO, UNKNOWN];

export const DAY_IN_MS = 1000 * 60 * 60 * 24;

export const DAYS = {
  THIRTY: 30,
  SIXTY: 60,
  NINETY: 90,
};

export const LOADING_VULNERABILITIES_ERROR_CODES = {
  UNAUTHORIZED: httpStatusCodes.UNAUTHORIZED,
  FORBIDDEN: httpStatusCodes.FORBIDDEN,
};
