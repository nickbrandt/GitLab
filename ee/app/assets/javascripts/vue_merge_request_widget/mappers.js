import { __ } from '~/locale';
import { RULE_TYPE_REGULAR, RULE_TYPE_FALLBACK } from 'ee/approvals/constants';

function mapApprovalRule(rule, settings) {
  if (rule.rule_type === RULE_TYPE_FALLBACK) {
    // Show a friendly name for the fallback rule
    return {
      ...rule,
      name: __('All Members'),
      fallback: true,
    };
  } else if (rule.rule_type === RULE_TYPE_REGULAR && !settings.multiple_approval_rules_available) {
    // Give a friendly name to the single rule
    return {
      ...rule,
      name: __('Merge Request'),
    };
  }

  return rule;
}

/**
 * Map the approval rules response for use by the MR widget
 */
export function mapApprovalRulesResponse(rules, settings) {
  return rules.map(x => mapApprovalRule(x, settings));
}

/**
 * Map the overall approvals response for use by the MR widget
 */
export function mapApprovalsResponse(data) {
  return {
    ...data,
    // Filter out empty names (fallback rule has no name) because
    // the empties would look weird.
    approvalRuleNamesLeft: data.multiple_approval_rules_available
      ? data.approval_rules_left.map(x => x.name).filter(x => x)
      : [],
  };
}
