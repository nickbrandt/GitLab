import mountMrEdit from 'ee/approvals/mount_mr_edit';
import mountBlockingMergeRequestsInput from 'ee/projects/merge_requests/blocking_mr_input';

export default () => {
  const { mountApprovalInput, mountTargetBranchAlert } = mountMrEdit(
    document.getElementById('js-mr-approvals-input'),
  );
  mountApprovalInput();
  mountTargetBranchAlert();
  mountBlockingMergeRequestsInput(document.getElementById('js-blocking-merge-requests-input'));
};
