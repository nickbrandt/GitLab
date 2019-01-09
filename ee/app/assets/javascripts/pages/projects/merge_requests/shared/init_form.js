import initApprovals from 'ee/approvals/setup_single_rule_approvals';
import mountApprovalInput from 'ee/approvals/mount_approval_input';

export default () => {
  initApprovals();
  mountApprovalInput(document.getElementById('js-mr-approvals-input'));
};
