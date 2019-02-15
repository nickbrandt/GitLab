import initApprovals from 'ee/approvals/setup_single_rule_approvals';
import mountApprovals from 'ee/approvals/mount_mr_edit';

export default () => {
  initApprovals();
  mountApprovals(document.getElementById('js-mr-approvals-input'));
};
