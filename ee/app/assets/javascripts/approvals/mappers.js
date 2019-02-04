import _ from 'underscore';

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
  sourceId: res.approval_project_rule_id,
  name: res.name,
  approvalsRequired: res.approvals_required,
  minApprovalsRequired: res.min_approvals_required || 0,
  approvers: res.approvers,
  users: res.users,
  groups: res.groups,
  isCodeOwner: res.code_owner,
});

export const mapApprovalSettingsResponse = res => ({
  rules: res.rules.map(mapApprovalRuleResponse),
  fallbackApprovalsRequired: res.fallback_approvals_required,
});

/**
 * This is a default rule (from project settings) which implies:
 * - Not a real MR rule, so no "id".
 * - The approvals required are the minimum.
 */
export const mapMRDefaultRule = ({ id, ...rule }) => ({
  ...rule,
  sourceId: id,
  minApprovalsRequired: rule.approvalsRequired,
});

export const mapMRApprovalSettingsResponse = res => ({
  rules: res.rules
    .map(mapApprovalRuleResponse)
    .map(res.approval_rules_overwritten ? x => x : mapMRDefaultRule)
    .filter(x => !x.isCodeOwner),
  fallbackApprovalsRequired: res.fallback_approvals_required,
  minFallbackApprovalsRequired: !_.isUndefined(res.min_fallback_approvals_required)
    ? res.min_fallback_approvals_required
    : res.fallback_approvals_required,
});
