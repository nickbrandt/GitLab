<script>
import { mapActions } from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import SecurityDashboard from './security_dashboard_vuex.vue';

export default {
  name: 'PipelineSecurityDashboard',
  components: {
    GlEmptyState,
    SecurityDashboard,
  },
  props: {
    dashboardDocumentation: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    sourceBranch: {
      type: String,
      required: true,
    },
    vulnerabilitiesEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: true,
    },
    loadingErrorIllustrations: {
      type: Object,
      required: true,
    },
  },
  created() {
    this.setSourceBranch(this.sourceBranch);
  },
  methods: {
    ...mapActions('vulnerabilities', ['setSourceBranch']),
  },
};
</script>

<template>
  <security-dashboard
    :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
    :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
    :lock-to-project="{ id: projectId }"
    :pipeline-id="pipelineId"
    :loading-error-illustrations="loadingErrorIllustrations"
  >
    <template #emptyState>
      <gl-empty-state
        :title="s__('SecurityReports|No vulnerabilities found for this pipeline')"
        :svg-path="emptyStateSvgPath"
        :description="
          s__(
            `SecurityReports|While it's rare to have no vulnerabilities for your pipeline, it can happen. In any event, we ask that you double check your settings to make sure all security scanning jobs have passed successfully.`,
          )
        "
        :primary-button-link="dashboardDocumentation"
        :primary-button-text="s__('SecurityReports|Learn more about setting up your dashboard')"
      />
    </template>
  </security-dashboard>
</template>
