<script>
import { s__ } from '~/locale';
import Modal from '~/vue_shared/components/gl_modal.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import ExpandButton from '~/vue_shared/components/expand_button.vue';

import DismissalNote from 'ee/vue_shared/security_reports/components/dismissal_note.vue';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import VulnerabilityDetails from 'ee/vue_shared/security_reports/components/vulnerability_details.vue';

export default {
  components: {
    DismissalNote,
    EventItem,
    ExpandButton,
    IssueNote,
    LoadingButton,
    MergeRequestNote,
    Modal,
    SolutionCard,
    SplitButton,
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
    canCreateIssuePermission: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateFeedbackPermission: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    actionButtons() {
      const buttons = [];
      const issueButton = {
        name: s__('ciReport|Create issue'),
        tagline: s__('ciReport|Investigate this vulnerability by creating an issue'),
        isLoading: this.modal.isCreatingNewIssue,
        action: 'createNewIssue',
      };
      const MRButton = {
        name: s__('ciReport|Create merge request'),
        tagline: s__('ciReport|Implement this solution by creating a merge request'),
        isLoading: this.modal.isCreatingMergeRequest,
        action: 'createMergeRequest',
      };

      if (!this.vulnerability.hasMergeRequest && this.remediation) {
        buttons.push(MRButton);
      }

      if (!this.vulnerability.hasIssue && this.canCreateIssuePermission) {
        buttons.push(issueButton);
      }

      return buttons;
    },
    revertTitle() {
      return this.vulnerability.isDismissed
        ? s__('ciReport|Undo dismiss')
        : s__('ciReport|Dismiss vulnerability');
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
    renderSolutionCard() {
      return this.solution || this.remediation;
    },
    /**
     * The slot for the footer should be rendered if any of the conditions is true.
     */
    shouldRenderFooterSection() {
      return (
        !this.modal.isResolved &&
        (this.canCreateFeedbackPermission || this.canCreateIssuePermission)
      );
    },
    vulnerability() {
      return this.modal.vulnerability;
    },
    issueFeedback() {
      return this.vulnerability && this.vulnerability.issue_feedback;
    },
    mergeRequestFeedback() {
      return this.vulnerability && this.vulnerability.merge_request_feedback;
    },
    dismissalFeedback() {
      return (
        this.vulnerability &&
        (this.vulnerability.dismissal_feedback || this.vulnerability.dismissalFeedback)
      );
    },
    valuedFields() {
      const { data } = this.modal;
      const result = {};

      Object.keys(data).forEach(key => {
        if (data[key].value && data[key].value.length) {
          result[key] = data[key];
        }
      });

      return result;
    },
  },
  methods: {
    handleDismissClick() {
      if (this.vulnerability.isDismissed) {
        this.$emit('revertDismissIssue');
      } else {
        this.$emit('dismissIssue');
      }
    },
  },
};
</script>
<template>
  <modal
    id="modal-mrwidget-security-issue"
    :header-title-text="modal.title"
    :class="{ 'modal-hide-footer': !shouldRenderFooterSection }"
    class="modal-security-report-dast"
  >
    <slot>
      <vulnerability-details :details="valuedFields" class="js-vulnerability-details" />

      <solution-card v-if="renderSolutionCard" :solution="solution" :remediation="remediation" />
      <hr v-else />

      <ul v-if="issueFeedback || mergeRequestFeedback" class="notes card my-4">
        <li v-if="issueFeedback" class="note">
          <issue-note :feedback="issueFeedback" :project="project" />
        </li>
        <li v-if="mergeRequestFeedback" class="note">
          <merge-request-note :feedback="mergeRequestFeedback" :project="project" />
        </li>
      </ul>

      <div class="card my-4">
        <dismissal-note v-if="dismissalFeedback" :feedback="dismissalFeedback" :project="project" />
      </div>

      <div class="prepend-top-20 append-bottom-10">
        <div class="col-sm-12 text-secondary">
          <a
            v-if="vulnerabilityFeedbackHelpPath"
            :href="vulnerabilityFeedbackHelpPath"
            class="js-link-vulnerabilityFeedbackHelpPath"
          >
            {{ s__('ciReport|Learn more about interacting with security reports (Alpha).') }}
          </a>
        </div>
      </div>

      <div v-if="modal.error" class="alert alert-danger">{{ modal.error }}</div>
    </slot>
    <div slot="footer">
      <template v-if="shouldRenderFooterSection">
        <button type="button" class="btn btn-default" data-dismiss="modal">
          {{ __('Cancel') }}
        </button>

        <loading-button
          v-if="canCreateFeedbackPermission"
          :loading="modal.isDismissingIssue"
          :disabled="modal.isDismissingIssue"
          :label="revertTitle"
          container-class="js-dismiss-btn btn btn-close"
          @click="handleDismissClick"
        />

        <split-button
          v-if="actionButtons.length > 1"
          :buttons="actionButtons"
          class="js-split-button"
          @createMergeRequest="$emit('createMergeRequest')"
          @createNewIssue="$emit('createNewIssue')"
        />

        <loading-button
          v-else-if="actionButtons.length > 0"
          :loading="actionButtons[0].isLoading"
          :disabled="actionButtons[0].isLoading"
          :label="actionButtons[0].name"
          container-class="btn btn-success btn-inverted"
          class="js-action-button"
          @click="$emit(actionButtons[0].action)"
        />
      </template>
    </div>
  </modal>
</template>
