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
      return this.modal.data.project;
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
        (this.vulnerability.dismissal_feedback || this.vulnerability.dismissalFeedback)
      );
    },
    isEditingExistingFeedback() {
      return this.dismissalFeedback && this.modal.isCommentingOnDismissal;
    },
    valuedFields() {
      const { data } = this.modal;
      const result = {};

      Object.keys(data).forEach(key => {
        if (data[key].value && data[key].value.length) {
          result[key] = data[key];
          if (key === 'file' && this.vulnerability.blob_path) {
            result[key].isLink = true;
            result[key].url = this.vulnerability.blob_path;
          }
        }
      });

      return result;
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
        project_id: this.project ? this.project.id : null,
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
      <vulnerability-details :details="valuedFields" class="js-vulnerability-details" />

      <solution-card
        :solution="solution"
        :remediation="remediation"
        :has-mr="vulnerability.hasMergeRequest"
        :has-remediation="hasRemediation"
        :has-download="canDownloadPatchForThisVulnerability"
        :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
      />

      <ul v-if="canReadIssueFeedback || canReadMergeRequestFeedback" class="notes card my-4">
        <li v-if="issueFeedback" class="note">
          <div class="card-body">
            <issue-note :feedback="issueFeedback" :project="project" />
          </div>
        </li>
        <li v-if="mergeRequestFeedback" class="note">
          <div class="card-body">
            <merge-request-note :feedback="mergeRequestFeedback" :project="project" />
          </div>
        </li>
      </ul>

      <div v-if="dismissalFeedback || modal.isCommentingOnDismissal" class="card my-4">
        <div class="card-body">
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
      </div>

      <div v-if="modal.error" class="alert alert-danger">{{ modal.error }}</div>
    </slot>
    <div slot="footer">
      <dismissal-comment-modal-footer
        v-if="modal.isCommentingOnDismissal"
        :is-dismissed="vulnerability.isDismissed"
        :is-editing-existing-feedback="isEditingExistingFeedback"
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
