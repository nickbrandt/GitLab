<script>
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import VulnerabilitiesCountList from 'ee/security_dashboard/components/vulnerability_count_list.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import ProjectVulnerabilitiesApp from 'ee/vulnerabilities/components/project_vulnerabilities_app.vue';

export default {
  components: {
    SecurityDashboardLayout,
    ProjectVulnerabilitiesApp,
    VulnerabilitiesCountList,
    Filters,
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
    projectFullPath: {
      type: String,
      required: true,
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
