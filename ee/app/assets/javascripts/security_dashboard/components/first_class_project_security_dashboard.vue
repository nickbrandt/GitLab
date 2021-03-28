<script>
import Cookies from 'js-cookie';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { vulnerabilitiesSeverityCountScopes } from '../constants';
import AutoFixUserCallout from './auto_fix_user_callout.vue';
import ReportsNotConfigured from './empty_states/reports_not_configured.vue';
import ProjectPipelineStatus from './project_pipeline_status.vue';
import ProjectVulnerabilitiesApp from './project_vulnerabilities.vue';
import SecurityDashboardLayout from './security_dashboard_layout.vue';

export default {
  components: {
    AutoFixUserCallout,
    ProjectPipelineStatus,
    ProjectVulnerabilitiesApp,
    ReportsNotConfigured,
    SecurityDashboardLayout,
    VulnerabilitiesCountList,
    CsvExportButton,
    Filters,
    SurveyRequestBanner,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    pipeline: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    const shouldShowAutoFixUserCallout =
      this.glFeatures.securityAutoFix && !Cookies.get('auto_fix_user_callout_dismissed');
    return {
      filters: null,
      shouldShowAutoFixUserCallout,
    };
  },
  computed: {
    hasNoPipeline() {
      return !this.pipeline?.id;
    },
  },
  methods: {
    handleFilterChange(filters) {
      this.filters = filters;
    },
    handleAutoFixUserCalloutClose() {
      Cookies.set('auto_fix_user_callout_dismissed', 'true');
      this.shouldShowAutoFixUserCallout = false;
    },
  },
  vulnerabilitiesSeverityCountScopes,
};
</script>

<template>
  <reports-not-configured v-if="hasNoPipeline" />
  <security-dashboard-layout v-else @filter-change="handleFilterChange">
    <template v-if="shouldShowAutoFixUserCallout" #banner>
      <auto-fix-user-callout @close="handleAutoFixUserCalloutClose" />
    </template>

    <template #pipeline>
      <project-pipeline-status :pipeline="pipeline" class="gl-mb-6" />
    </template>

    <project-vulnerabilities-app :filters="filters" />
  </security-dashboard-layout>
</template>
