<script>
import { mapActions } from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import SecurityDashboard from './security_dashboard_vuex.vue';
import { fetchPolicies } from '~/lib/graphql';
import pipelineSecurityReportSummaryQuery from '../graphql/pipeline_security_report_summary.query.graphql';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'PipelineSecurityDashboard',
  components: {
    GlEmptyState,
    SecurityDashboard,
  },
  mixins: [glFeatureFlagsMixin()],
  apollo: {
    securityReportSummary: {
      query: pipelineSecurityReportSummaryQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          fullPath: this.projectFullPath,
          pipelineId: this.pipelineId,
        };
      },
      update(data) {
        return data?.project?.pipelines?.nodes?.[0]?.securityReportSummary;
      },
      skip() {
        return !this.glFeatures.pipelinesSecurityReportSummary;
      },
    },
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
    projectFullPath: {
      type: String,
      required: false,
      default: '',
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
    :security-report-summary="securityReportSummary"
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
