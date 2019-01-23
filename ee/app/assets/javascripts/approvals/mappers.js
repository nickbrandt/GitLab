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
  name: res.name,
  approvalsRequired: res.approvals_required,
  approvers: res.approvers,
  users: res.users,
  groups: res.groups,
  isCodeOwner: res.code_owner,
});

export const mapApprovalSettingsResponse = res => ({
  rules: res.rules.map(mapApprovalRuleResponse),
  fallbackApprovalsRequired: res.fallback_approvals_required,
  hasCustomRules: res.approval_rules_overwritten,
});
