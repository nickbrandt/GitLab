<script>
import { GlDeprecatedButton, GlLoadingIcon } from '@gitlab/ui';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import UsersCache from '~/lib/utils/users_cache';
import ResolutionAlert from './resolution_alert.vue';
import VulnerabilityStateDropdown from './vulnerability_state_dropdown.vue';
import StatusDescription from './status_description.vue';
import { VULNERABILITY_STATE_OBJECTS } from '../constants';
import VulnerabilitiesEventBus from './vulnerabilities_event_bus';

export default {
  name: 'VulnerabilityHeader',
  components: {
    GlDeprecatedButton,
    GlLoadingIcon,
    ResolutionAlert,
    VulnerabilityStateDropdown,
    StatusDescription,
  },

  props: {
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
      isCreatingIssue: false,
      isLoadingUser: false,
      vulnerability: this.initialVulnerability,
      user: undefined,
    };
  },

  computed: {
    hasIssue() {
      return Boolean(this.finding.issue_feedback?.issue_iid);
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
      this.isCreatingIssue = true;
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
          this.isCreatingIssue = false;
          createFlash(
            s__('VulnerabilityManagement|Something went wrong, could not create an issue.'),
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
        <gl-loading-icon v-if="isLoadingVulnerability" class="d-inline" />
        <vulnerability-state-dropdown
          v-else
          :initial-state="vulnerability.state"
          @change="changeVulnerabilityState"
        />
        <gl-deprecated-button
          v-if="!hasIssue"
          ref="create-issue-btn"
          class="ml-2"
          variant="success"
          category="secondary"
          :loading="isCreatingIssue"
          @click="createIssue"
        >
          {{ s__('VulnerabilityManagement|Create issue') }}
        </gl-deprecated-button>
      </div>
    </div>
  </div>
</template>
