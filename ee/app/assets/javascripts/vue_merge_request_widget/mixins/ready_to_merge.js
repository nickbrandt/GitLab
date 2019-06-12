import { ATMTWPS_MERGE_STRATEGY, MT_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import { __ } from '~/locale';

export default {
  computed: {
    isApprovalNeeded() {
      return this.mr.hasApprovalsAvailable ? !this.mr.isApproved : false;
    },
    isMergeButtonDisabled() {
      const { commitMessage } = this;
      return Boolean(
        !commitMessage.length ||
          !this.shouldShowMergeControls ||
          this.isMakingRequest ||
          this.isApprovalNeeded ||
          this.mr.preventMerge,
      );
    },
    autoMergeText() {
      if (this.mr.preferredAutoMergeStrategy === ATMTWPS_MERGE_STRATEGY) {
        if (this.mr.mergeTrainsCount === 0) {
          return __('Start merge train when pipeline succeeds');
        }
        return __('Add to merge train when pipeline succeeds');
      } else if (this.mr.preferredAutoMergeStrategy === MT_MERGE_STRATEGY) {
        if (this.mr.mergeTrainsCount === 0) {
          return __('Start merge train');
        }
        return __('Add to merge train');
      }
      return __('Merge when pipeline succeeds');
    },
  },
};
