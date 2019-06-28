import { s__, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';

const MAX_TOAST_MESSAGE_LENGTH = 75;
const VULNERABILITY_DISMISSED_MESSAGE = s__('Vulnerability|Dismissed ‘%{vulnerabilityName}’');

/**
 * Ensures the given vulnerability name is truncated so the total interpolated message is
 * not more than `maxLength` characters long.
 */
const getTruncatedMessage = (template, name, maxLength = MAX_TOAST_MESSAGE_LENGTH) => {
  let vulnerabilityName = name;
  const interpolated = sprintf(template, { vulnerabilityName });
  const excess = Math.max(0, interpolated.length - maxLength);
  if (excess > 0) {
    vulnerabilityName = truncate(vulnerabilityName, vulnerabilityName.length - excess);
    return sprintf(template, { vulnerabilityName });
  }

  return interpolated;
};

// eslint-disable-next-line import/prefer-default-export
export const getVulnerabilityDismissedMessage = name =>
  getTruncatedMessage(VULNERABILITY_DISMISSED_MESSAGE, name);
