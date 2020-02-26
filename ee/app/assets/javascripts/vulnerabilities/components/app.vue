<script>
import { GlLoadingIcon } from '@gitlab/ui';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import VulnerabilityStateDropdown from './vulnerability_state_dropdown.vue';

export default {
  components: {
    GlLoadingIcon,
    VulnerabilityStateDropdown,
    LoadingButton,
  },

  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
    finding: {
      type: Object,
      required: true,
    },
    createIssueUrl: {
      type: String,
      required: true,
    },
  },

  data: () => ({
    isLoading: false,
    isCreatingIssue: false,
  }),

  methods: {
    onVulnerabilityStateChange(newState) {
      this.isLoading = true;

      axios
        .post(`/api/v4/vulnerabilities/${this.vulnerability.id}/${newState}`)
        // Reload the page for now since the rest of the page is still a static haml file.
        .then(() => window.location.reload(true))
        .catch(() => {
          createFlash(
            s__(
              'VulnerabilityManagement|Something went wrong, could not update vulnerability state.',
            ),
          );
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    createIssue() {
      this.isCreatingIssue = true;
      axios
        .post(this.createIssueUrl, {
          vulnerability_feedback: {
            feedback_type: 'issue',
            category: this.vulnerability.report_type,
            project_fingerprint: this.finding.project_fingerprint,
            vulnerability_data: { ...this.vulnerability, category: this.vulnerability.report_type },
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
    <gl-loading-icon v-if="isLoading" />
    <vulnerability-state-dropdown
      v-else
      :state="vulnerability.state"
      @change="onVulnerabilityStateChange"
    />
    <loading-button
      ref="create-issue-btn"
      class="align-items-center d-inline-flex"
      :loading="isCreatingIssue"
      :label="s__('VulnerabilityManagement|Create issue')"
      container-class="btn btn-success btn-inverted"
      @click="createIssue"
    />
  </div>
</template>
