<script>
import { GlDeprecatedButton, GlLoadingIcon } from '@gitlab/ui';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import download from '~/lib/utils/downloader';
import { redirectTo } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import UsersCache from '~/lib/utils/users_cache';
import ResolutionAlert from './resolution_alert.vue';
import VulnerabilityStateDropdown from './vulnerability_state_dropdown.vue';
import StatusDescription from './status_description.vue';
import { VULNERABILITY_STATE_OBJECTS, FEEDBACK_TYPES, HEADER_ACTION_BUTTONS } from '../constants';
import VulnerabilitiesEventBus from './vulnerabilities_event_bus';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';

export default {
  name: 'VulnerabilityHeader',
  components: {
    GlDeprecatedButton,
    GlLoadingIcon,
    ResolutionAlert,
    VulnerabilityStateDropdown,
    SplitButton,
    StatusDescription,
  },

  props: {
    createMrUrl: {
      type: String,
      required: true,
    },
    initialVulnerability: {
      type: Object,
      required: true,
    },
    finding: {
      type: Object,
      required: true,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    createIssueUrl: {
      type: String,
      required: true,
    },
    projectFingerprint: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      isLoadingVulnerability: false,
      isProcessingAction: false,
      isLoadingUser: false,
      vulnerability: this.initialVulnerability,
      user: undefined,
    };
  },

  computed: {
    actionButtons() {
      const buttons = [];

      if (this.canCreateMergeRequest) {
        buttons.push(HEADER_ACTION_BUTTONS.mergeRequestCreation);
      }

      if (this.canDownloadPatch) {
        buttons.push(HEADER_ACTION_BUTTONS.patchDownload);
      }

      if (!this.hasIssue) {
        buttons.push(HEADER_ACTION_BUTTONS.issueCreation);
      }

      return buttons;
    },
    canDownloadPatch() {
      return (
        this.vulnerability.state !== VULNERABILITY_STATE_OBJECTS.resolved.state &&
        !this.vulnerability.hasMr &&
        this.hasRemediation
      );
    },
    hasIssue() {
      return Boolean(this.finding.issue_feedback?.issue_iid);
    },
    hasRemediation() {
      const { remediations } = this.finding;
      return Boolean(remediations && remediations[0]?.diff?.length > 0);
    },
    canCreateMergeRequest() {
      return (
        !this.finding.merge_request_feedback?.merge_request_path &&
        Boolean(this.createMrUrl) &&
        this.hasRemediation
      );
    },
    statusBoxStyle() {
      // Get the badge variant based on the vulnerability state, defaulting to 'expired'.
      return VULNERABILITY_STATE_OBJECTS[this.vulnerability.state]?.statusBoxStyle || 'expired';
    },
    showResolutionAlert() {
      return (
        this.vulnerability.resolved_on_default_branch &&
        this.vulnerability.state !== VULNERABILITY_STATE_OBJECTS.resolved.state
      );
    },
  },

  watch: {
    'vulnerability.state': {
      immediate: true,
      handler(state) {
        const id = this.vulnerability[`${state}_by_id`];

        if (id === undefined) return; // Don't do anything if there's no ID.

        this.isLoadingUser = true;

        UsersCache.retrieveById(id)
          .then(userData => {
            this.user = userData;
          })
          .catch(() => {
            createFlash(s__('VulnerabilityManagement|Something went wrong, could not get user.'));
          })
          .finally(() => {
            this.isLoadingUser = false;
          });
      },
    },
  },

  methods: {
    triggerClick(action) {
      const fn = this[action];
      if (typeof fn === 'function') fn();
    },
    changeVulnerabilityState(newState) {
      this.isLoadingVulnerability = true;

      Api.changeVulnerabilityState(this.vulnerability.id, newState)
        .then(({ data }) => {
          Object.assign(this.vulnerability, data);
        })
        .catch(() => {
          createFlash(
            s__(
              'VulnerabilityManagement|Something went wrong, could not update vulnerability state.',
            ),
          );
        })
        .finally(() => {
          this.isLoadingVulnerability = false;
          VulnerabilitiesEventBus.$emit('VULNERABILITY_STATE_CHANGE');
        });
    },
    createIssue() {
      this.isProcessingAction = true;
      axios
        .post(this.createIssueUrl, {
          vulnerability_feedback: {
            feedback_type: FEEDBACK_TYPES.ISSUE,
            category: this.vulnerability.report_type,
            project_fingerprint: this.projectFingerprint,
            vulnerability_data: {
              ...this.vulnerability,
              ...this.finding,
              category: this.vulnerability.report_type,
              vulnerability_id: this.vulnerability.id,
            },
          },
        })
        .then(({ data: { issue_url } }) => {
          redirectTo(issue_url);
        })
        .catch(() => {
          this.isProcessingAction = false;
          createFlash(
            s__('VulnerabilityManagement|Something went wrong, could not create an issue.'),
          );
        });
    },
    createMergeRequest() {
      this.isProcessingAction = true;
      axios
        .post(this.createMrUrl, {
          vulnerability_feedback: {
            feedback_type: FEEDBACK_TYPES.MERGE_REQUEST,
            category: this.vulnerability.report_type,
            project_fingerprint: this.projectFingerprint,
            vulnerability_data: {
              ...this.vulnerability,
              ...this.finding,
              category: this.vulnerability.report_type,
              target_branch: this.pipeline.sourceBranch,
            },
          },
        })
        .then(({ data: { merge_request_path } }) => {
          redirectTo(merge_request_path);
        })
        .catch(() => {
          this.isProcessingAction = false;
          createFlash(
            s__('ciReport|There was an error creating the merge request. Please try again.'),
          );
        });
    },
    downloadPatch() {
      download({ fileData: this.finding.remediations[0].diff, fileName: `remediation.patch` });
    },
  },
};
</script>

<template>
  <div>
    <resolution-alert
      v-if="showResolutionAlert"
      :vulnerability-id="vulnerability.id"
      :default-branch-name="vulnerability.project_default_branch"
    />
    <div class="detail-page-header">
      <div class="detail-page-header-body align-items-center">
        <gl-loading-icon v-if="isLoadingVulnerability" class="mr-2" />
        <span
          v-else
          ref="badge"
          :class="
            `text-capitalize align-self-center issuable-status-box status-box status-box-${statusBoxStyle}`
          "
        >
          {{ vulnerability.state }}
        </span>

        <status-description
          class="issuable-meta"
          :vulnerability="vulnerability"
          :pipeline="pipeline"
          :user="user"
          :is-loading-vulnerability="isLoadingVulnerability"
          :is-loading-user="isLoadingUser"
        />
      </div>

      <div class="detail-page-header-actions align-items-center">
        <label class="mb-0 mx-2">{{ __('Status') }}</label>
        <gl-loading-icon v-if="isLoadingVulnerability" class="d-inline" />
        <vulnerability-state-dropdown
          v-else
          :initial-state="vulnerability.state"
          @change="changeVulnerabilityState"
        />
        <split-button
          v-if="actionButtons.length > 1"
          :buttons="actionButtons"
          :disabled="isProcessingAction"
          class="js-split-button"
          @createMergeRequest="createMergeRequest"
          @createIssue="createIssue"
          @downloadPatch="downloadPatch"
        />
        <gl-deprecated-button
          v-else-if="actionButtons.length > 0"
          class="ml-2"
          variant="success"
          category="secondary"
          :loading="isProcessingAction"
          @click="triggerClick(actionButtons[0].action)"
        >
          {{ actionButtons[0].name }}
        </gl-deprecated-button>
      </div>
    </div>
  </div>
</template>
