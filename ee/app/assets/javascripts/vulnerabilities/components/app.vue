<script>
import { GlButton, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ResolutionAlert from './resolution_alert.vue';
import VulnerabilityStateDropdown from './vulnerability_state_dropdown.vue';
import { VULNERABILITY_STATES } from '../constants';

export default {
  name: 'VulnerabilityManagementApp',
  components: {
    GlButton,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    ResolutionAlert,
    TimeAgoTooltip,
    VulnerabilityStateDropdown,
  },

  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
    pipeline: {
      type: Object,
      required: false,
      default: undefined,
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
      state: this.vulnerability.state,
    };
  },

  computed: {
    statusBoxStyle() {
      // Get the badge variant based on the vulnerability state, defaulting to 'expired'.
      return VULNERABILITY_STATES[this.state]?.statusBoxStyle || 'expired';
    },
    showResolutionAlert() {
      return this.vulnerability.resolved_on_default_branch && this.state !== 'resolved';
    },
  },

  methods: {
    onVulnerabilityStateChange(newState) {
      this.isLoadingVulnerability = true;

      Api.changeVulnerabilityState(this.vulnerability.id, newState)
        .then(({ data }) => {
          this.state = data.state;
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
      :default-branch-name="vulnerability.default_branch_name"
    />
    <div class="detail-page-header">
      <div class="detail-page-header-body lh-4 align-items-center">
        <gl-loading-icon v-if="isLoadingVulnerability" class="mr-2" />
        <span
          v-else
          ref="badge"
          :class="
            `text-capitalize align-self-center issuable-status-box status-box status-box-${statusBoxStyle}`
          "
        >
          {{ state }}
        </span>

        <span v-if="pipeline" class="issuable-meta">
          <gl-sprintf :message="__('Detected %{timeago} in pipeline %{pipelineLink}')">
            <template #timeago>
              <time-ago-tooltip :time="pipeline.created_at" />
            </template>
            <template v-if="pipeline.id" #pipelineLink>
              <gl-link :href="pipeline.url" class="link" target="_blank">{{ pipeline.id }}</gl-link>
            </template>
          </gl-sprintf>
        </span>

        <time-ago-tooltip v-else class="issuable-meta" :time="vulnerability.created_at" />
      </div>

      <div class="detail-page-header-actions align-items-center">
        <label class="mb-0 mx-2">{{ __('Status') }}</label>
        <gl-loading-icon v-if="isLoadingVulnerability" class="d-inline" />
        <vulnerability-state-dropdown
          v-else
          :initial-state="state"
          @change="onVulnerabilityStateChange"
        />
        <gl-button
          ref="create-issue-btn"
          class="ml-2"
          variant="success"
          category="secondary"
          :loading="isCreatingIssue"
          @click="createIssue"
        >
          {{ s__('VulnerabilityManagement|Create issue') }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
