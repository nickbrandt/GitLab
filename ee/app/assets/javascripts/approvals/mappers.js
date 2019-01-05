export const mapApprovalRuleRequest = req => ({
  name: req.name,
  approvals_required: req.approvalsRequired,
  users: req.users,
  groups: req.groups,
});

export const mapApprovalRuleResponse = res => ({
  id: res.id,
  name: res.name,
  approvalsRequired: res.approvals_required,
  approvers: res.approvers,
  users: res.users,
  groups: res.groups,
});

export const mapApprovalRulesResponse = req => ({
  rules: req.rules.map(mapApprovalRuleResponse),
});
