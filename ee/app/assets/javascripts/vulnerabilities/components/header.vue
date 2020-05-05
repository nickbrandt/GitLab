<script>
import { GlLoadingIcon } from '@gitlab/ui';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import UsersCache from '~/lib/utils/users_cache';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import ResolutionAlert from './resolution_alert.vue';
import VulnerabilityStateDropdown from './vulnerability_state_dropdown.vue';
import StatusDescription from './status_description.vue';
import { VULNERABILITY_STATE_OBJECTS } from '../constants';
import VulnerabilitiesEventBus from './vulnerabilities_event_bus';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';

export default {
  name: 'VulnerabilityHeader',
  components: {
    GlLoadingIcon,
    LoadingButton,
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
    targetBranch: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      isLoadingVulnerability: false,
      isProcessing: false,
      isLoadingUser: false,
      vulnerability: this.initialVulnerability,
      user: undefined,
    };
  },

  computed: {
    actionButtons() {
      const buttons = [];
      const issueButton = {
        name: s__('ciReport|Create issue'),
        tagline: s__('ciReport|Investigate this vulnerability by creating an issue'),
        isLoading: this.isProcessing,
        action: 'createIssue',
      };
      const MergeRequestButton = {
        name: s__('ciReport|Resolve with merge request'),
        tagline: s__('ciReport|Automatically apply the patch in a new branch'),
        isLoading: this.isProcessing,
        action: 'createMergeRequest',
      };

      if (this.canCreateMergeRequest) {
        buttons.push(MergeRequestButton);
      }

      if (!this.hasIssue) {
        buttons.push(issueButton);
      }

      return buttons;
    },
    hasIssue() {
      return Boolean(this.finding.issue_feedback?.issue_iid);
    },
    canCreateMergeRequest() {
      return (
        !this.finding.merge_request_feedback.merge_request_path &&
        Boolean(this.createMrUrl) &&
        Boolean(this.finding.remediations)
      );
    },
    statusBoxStyle() {
      // Get the badge variant based on the vulnerability state, defaulting to 'expired'.
      return VULNERABILITY_STATE_OBJECTS[this.vulnerability.state]?.statusBoxStyle || 'expired';
    },
    showResolutionAlert() {
      return (
        this.vulnerability.resolved_on_default_branch && this.vulnerability.state !== 'resolved'
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
      this[action]();
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
      this.isProcessing = true;
      axios
        .post(this.createIssueUrl, {
          vulnerability_feedback: {
            feedback_type: 'issue',
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
          this.isProcessing = false;
          createFlash(
            s__('VulnerabilityManagement|Something went wrong, could not create an issue.'),
          );
        });
    },
    createMergeRequest() {
      this.isProcessing = true;
      axios
        .post(this.createMrUrl, {
          vulnerability_feedback: {
            feedback_type: 'merge_request',
            category: this.vulnerability.report_type,
            project_fingerprint: this.projectFingerprint,
            vulnerability_data: {
              ...this.vulnerability,
              ...this.finding,
              category: this.vulnerability.report_type,
              target_branch: this.targetBranch,
            },
          },
        })
        .then(({ data: { merge_request_path } }) => {
          redirectTo(merge_request_path);
        })
        .catch(() => {
          this.isProcessing = false;
          createFlash(
            s__('ciReport|There was an error creating the merge request. Please try again.'),
          );
        });
    },
  },
};
</script>

<template>
  <div>
    <resolution-alert
      v-if="showResolutionAlert"
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
        <template>
          <gl-loading-icon v-if="isLoadingVulnerability" class="d-inline" />
          <vulnerability-state-dropdown
            v-else
            :initial-state="vulnerability.state"
            @change="changeVulnerabilityState"
          />
        </template>
        <template>
          <split-button
            v-if="actionButtons.length > 1"
            :buttons="actionButtons"
            :disabled="isProcessing"
            class="js-split-button"
            data-qa-selector="resolve_split_button"
            @createMergeRequest="createMergeRequest"
            @createIssue="createIssue"
          />
          <loading-button
            v-else-if="actionButtons.length > 0"
            ref="single-action-btn"
            :loading="actionButtons[0].isLoading"
            :disabled="actionButtons[0].isLoading"
            :label="actionButtons[0].name"
            container-class="ml-2 btn btn-success btn-inverted"
            class="js-action-button"
            @click="triggerClick(actionButtons[0].action)"
          />
        </template>
      </div>
    </div>
  </div>
</template>
