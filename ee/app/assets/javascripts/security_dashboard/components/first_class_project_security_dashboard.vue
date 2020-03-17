<script>
import ProjectVulnerabilitiesApp from 'ee/vulnerabilities/components/project_vulnerabilities_app.vue';
import ReportsNotConfigured from 'ee/security_dashboard/components/empty_states/reports_not_configured.vue';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import VulnerabilitiesCountList from 'ee/security_dashboard/components/vulnerability_count_list.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';

export default {
  components: {
    ProjectVulnerabilitiesApp,
    ReportsNotConfigured,
    SecurityDashboardLayout,
    VulnerabilitiesCountList,
    Filters,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    securityDashboardHelpPath: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    dashboardDocumentation: {
      type: String,
      required: false,
      default: '',
    },
    hasPipelineData: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      filters: {},
    };
  },
  methods: {
    handleFilterChange(filters) {
      this.filters = filters;
    },
  },
};
</script>

<template>
  <div>
    <template v-if="hasPipelineData">
      <security-dashboard-layout>
        <template #header>
          <vulnerabilities-count-list :project-full-path="projectFullPath" />
          <filters @filterChange="handleFilterChange" />
        </template>
        <project-vulnerabilities-app
          :dashboard-documentation="dashboardDocumentation"
          :empty-state-svg-path="emptyStateSvgPath"
          :project-full-path="projectFullPath"
          :filters="filters"
        />
      </security-dashboard-layout>
    </template>
    <reports-not-configured
      v-else
      :svg-path="emptyStateSvgPath"
      :help-path="securityDashboardHelpPath"
    />
  </div>
</template>
