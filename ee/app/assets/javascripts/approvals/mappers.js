import _ from 'underscore';
import { RULE_TYPE_REGULAR, RULE_TYPE_FALLBACK } from './constants';

export const mapApprovalRuleRequest = req => ({
  name: req.name,
  approvals_required: req.approvalsRequired,
  users: req.users,
  groups: req.groups,
});

export const mapApprovalFallbackRuleRequest = req => ({
  fallback_approvals_required: req.approvalsRequired,
});

export const mapApprovalRuleResponse = res => ({
  id: res.id,
  hasSource: !!res.source_rule,
  name: res.name,
  approvalsRequired: res.approvals_required,
  minApprovalsRequired: res.source_rule ? res.source_rule.approvals_required : 0,
  approvers: res.approvers,
  users: res.users,
  groups: res.groups,
});

export const mapApprovalSettingsResponse = res => ({
  rules: res.rules.map(mapApprovalRuleResponse),
  fallbackApprovalsRequired: res.fallback_approvals_required,
});

/**
 * Map the sourced approval rule response for the MR view
 *
 * This rule is sourced from project settings, which implies:
 * - Not a real MR rule, so no "id".
 * - The approvals required are the minimum.
 */
export const mapMRSourceRule = ({ id, ...rule }) => ({
  ...rule,
  hasSource: true,
  sourceId: id,
  minApprovalsRequired: rule.approvalsRequired || 0,
});

/**
 * Map the approval settings response for the MR view
 *
 * - Only show regular rules.
 * - If needed, extract the fallback approvals required
 *   from the fallback rule.
 */
export const mapMRApprovalSettingsResponse = res => {
  const rulesByType = _.groupBy(res.rules, x => x.rule_type);

  const regularRules = rulesByType[RULE_TYPE_REGULAR] || [];

  const [fallback] = rulesByType[RULE_TYPE_FALLBACK] || [];
  const fallbackApprovalsRequired = fallback
    ? fallback.approvals_required
    : res.fallback_approvals_required || 0;

  return {
    rules: regularRules
      .map(mapApprovalRuleResponse)
      .map(res.approval_rules_overwritten ? x => x : mapMRSourceRule),
    fallbackApprovalsRequired,
    minFallbackApprovalsRequired: 0,
  };
};
