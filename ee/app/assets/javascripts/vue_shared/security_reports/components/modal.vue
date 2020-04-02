<script>
import DismissalNote from 'ee/vue_shared/security_reports/components/dismissal_note.vue';
import DismissalCommentBoxToggle from 'ee/vue_shared/security_reports/components/dismissal_comment_box_toggle.vue';
import DismissalCommentModalFooter from 'ee/vue_shared/security_reports/components/dismissal_comment_modal_footer.vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import ModalFooter from 'ee/vue_shared/security_reports/components/modal_footer.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import VulnerabilityDetails from 'ee/vue_shared/security_reports/components/vulnerability_details.vue';
import DeprecatedModal2 from '~/vue_shared/components/deprecated_modal_2.vue';
import { __ } from '~/locale';

export default {
  components: {
    DismissalNote,
    DismissalCommentBoxToggle,
    DismissalCommentModalFooter,
    IssueNote,
    MergeRequestNote,
    Modal: DeprecatedModal2,
    ModalFooter,
    SolutionCard,
    VulnerabilityDetails,
  },
  props: {
    modal: {
      type: Object,
      required: true,
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    canCreateIssue: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateMergeRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDismissVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
    isCreatingIssue: {
      type: Boolean,
      required: true,
    },
    isDismissingVulnerability: {
      type: Boolean,
      required: true,
    },
    isCreatingMergeRequest: {
      type: Boolean,
      required: true,
    },
  },
  data: () => ({
    localDismissalComment: '',
    dismissalCommentErrorMessage: '',
  }),
  computed: {
    canCreateIssueForThisVulnerability() {
      return Boolean(!this.isResolved && !this.vulnerability.hasIssue && this.canCreateIssue);
    },
    canCreateMergeRequestForThisVulnerability() {
      return Boolean(!this.isResolved && !this.vulnerability.hasMergeRequest && this.remediation);
    },
    canDismissThisVulnerability() {
      return Boolean(!this.isResolved && this.canDismissVulnerability);
    },
    canDownloadPatchForThisVulnerability() {
      const remediationDiff = this.remediation && this.remediation.diff;
      return Boolean(
        !this.isResolved &&
          remediationDiff &&
          remediationDiff.length > 0 &&
          (!this.vulnerability.hasMergeRequest && this.remediation),
      );
    },
    isResolved() {
      return Boolean(this.modal.isResolved);
    },
    hasRemediation() {
      return Boolean(this.remediation);
    },
    hasDismissedBy() {
      return (
        this.vulnerability &&
        this.vulnerability.dismissalFeedback &&
        this.vulnerability.dismissalFeedback.pipeline &&
        this.vulnerability.dismissalFeedback.author
      );
    },
    project() {
      return this.modal.project;
    },
    solution() {
      return this.vulnerability && this.vulnerability.solution;
    },
    remediation() {
      return (
        this.vulnerability && this.vulnerability.remediations && this.vulnerability.remediations[0]
      );
    },
    vulnerability() {
      return this.modal.vulnerability;
    },
    issueFeedback() {
      return this.vulnerability && this.vulnerability.issue_feedback;
    },
    canReadIssueFeedback() {
      return this.issueFeedback && this.issueFeedback.issue_url;
    },
    mergeRequestFeedback() {
      return this.vulnerability && this.vulnerability.merge_request_feedback;
    },
    canReadMergeRequestFeedback() {
      return this.mergeRequestFeedback && this.mergeRequestFeedback.merge_request_path;
    },
    dismissalFeedback() {
      return (
        this.vulnerability &&
        // grouped security reports are populating `dismissalFeedback` and the dashboards `dismissal_feedback`
        // https://gitlab.com/gitlab-org/gitlab/issues/207489 aims to use the same property in all cases
        (this.vulnerability.dismissalFeedback || this.vulnerability.dismissal_feedback)
      );
    },
    isEditingExistingFeedback() {
      return this.dismissalFeedback && this.modal.isCommentingOnDismissal;
    },
    dismissalFeedbackObject() {
      if (this.dismissalFeedback) {
        return this.dismissalFeedback;
      }

      // If we don't have access to the feedback object, we can preempt the data with properties taken from the `gon` variable

      const {
        current_user_avatar_url,
        current_user_fullname,
        current_user_id,
        current_username,
      } = gon;

      return {
        author: {
          id: current_user_id,
          name: current_user_fullname,
          username: current_username,
          state: 'active',
          avatar_url: current_user_avatar_url,
        },
      };
    },
  },
  methods: {
    handleDismissalCommentSubmission() {
      if (this.dismissalFeedback) {
        this.addDismissalComment();
      } else {
        this.addCommentAndDismiss();
      }
    },
    addCommentAndDismiss() {
      if (this.localDismissalComment.length) {
        this.$emit('dismissVulnerability', this.localDismissalComment);
      } else {
        this.addDismissalError();
      }
    },
    addDismissalComment() {
      if (this.localDismissalComment.length) {
        this.$emit('addDismissalComment', this.localDismissalComment);
      } else {
        this.addDismissalError();
      }
    },
    addDismissalError() {
      this.dismissalCommentErrorMessage = __('Please add a comment in the text area above');
    },
    clearDismissalError() {
      this.dismissalCommentErrorMessage = '';
    },
  },
};
</script>
<template>
  <modal
    id="modal-mrwidget-security-issue"
    :header-title-text="modal.title"
    data-qa-selector="vulnerability_modal_content"
    class="modal-security-report-dast"
  >
    <slot>
      <vulnerability-details :vulnerability="vulnerability" class="js-vulnerability-details" />

      <solution-card
        :solution="solution"
        :remediation="remediation"
        :has-mr="vulnerability.hasMergeRequest"
        :has-remediation="hasRemediation"
        :has-download="canDownloadPatchForThisVulnerability"
        :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
      />

      <div v-if="canReadIssueFeedback || canReadMergeRequestFeedback" class="card my-4">
        <issue-note
          v-if="issueFeedback"
          :feedback="issueFeedback"
          :project="project"
          class="card-body"
        />
        <merge-request-note
          v-if="mergeRequestFeedback"
          :feedback="mergeRequestFeedback"
          :project="project"
          class="card-body"
        />
      </div>

      <div v-if="dismissalFeedback || modal.isCommentingOnDismissal" class="card card-body my-4">
        <dismissal-note
          :feedback="dismissalFeedbackObject"
          :is-commenting-on-dismissal="modal.isCommentingOnDismissal"
          :is-showing-delete-buttons="modal.isShowingDeleteButtons"
          :project="project"
          :show-dismissal-comment-actions="
            !dismissalFeedback || !dismissalFeedback.comment_details || !isEditingExistingFeedback
          "
          @editVulnerabilityDismissalComment="$emit('editVulnerabilityDismissalComment')"
          @showDismissalDeleteButtons="$emit('showDismissalDeleteButtons')"
          @hideDismissalDeleteButtons="$emit('hideDismissalDeleteButtons')"
          @deleteDismissalComment="$emit('deleteDismissalComment')"
        />
        <dismissal-comment-box-toggle
          v-if="
            !dismissalFeedback || !dismissalFeedback.comment_details || isEditingExistingFeedback
          "
          v-model="localDismissalComment"
          :dismissal-comment="
            dismissalFeedback &&
              dismissalFeedback.comment_details &&
              dismissalFeedback.comment_details.comment
          "
          :is-active="modal.isCommentingOnDismissal"
          :error-message="dismissalCommentErrorMessage"
          @openDismissalCommentBox="$emit('openDismissalCommentBox')"
          @submit="handleDismissalCommentSubmission"
          @clearError="clearDismissalError"
        />
      </div>

      <div v-if="modal.error" class="alert alert-danger">{{ modal.error }}</div>
    </slot>
    <div slot="footer">
      <dismissal-comment-modal-footer
        v-if="modal.isCommentingOnDismissal"
        :is-dismissed="vulnerability.isDismissed"
        :is-editing-existing-feedback="isEditingExistingFeedback"
        :is-dismissing-vulnerability="isDismissingVulnerability"
        @addCommentAndDismiss="addCommentAndDismiss"
        @addDismissalComment="addDismissalComment"
        @cancel="$emit('closeDismissalCommentBox')"
      />
      <modal-footer
        v-else
        ref="footer"
        :modal="modal"
        :vulnerability="vulnerability"
        :disabled="modal.isShowingDeleteButtons"
        :can-create-issue="canCreateIssueForThisVulnerability"
        :can-create-merge-request="canCreateMergeRequestForThisVulnerability"
        :can-download-patch="canDownloadPatchForThisVulnerability"
        :can-dismiss-vulnerability="canDismissThisVulnerability"
        :is-dismissed="vulnerability.isDismissed"
        :is-creating-issue="isCreatingIssue"
        :is-dismissing-vulnerability="isDismissingVulnerability"
        :is-creating-merge-request="isCreatingMergeRequest"
        @createMergeRequest="$emit('createMergeRequest')"
        @createNewIssue="$emit('createNewIssue')"
        @dismissVulnerability="$emit('dismissVulnerability')"
        @openDismissalCommentBox="$emit('openDismissalCommentBox')"
        @revertDismissVulnerability="$emit('revertDismissVulnerability')"
        @downloadPatch="$emit('downloadPatch')"
      />
    </div>
  </modal>
</template>
