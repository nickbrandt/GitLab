import mountApprovals from 'ee/approvals/mount_mr_edit';
import mountBlockingMergeRequestsInput from 'ee/projects/merge_requests/blocking_mr_input';

export default () => {
  mountApprovals(document.getElementById('js-mr-approvals-input'));
  mountBlockingMergeRequestsInput(document.getElementById('js-blocking-merge-requests-input'));
};
