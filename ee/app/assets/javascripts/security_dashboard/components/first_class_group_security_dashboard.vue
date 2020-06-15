<script>
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import GroupSecurityVulnerabilities from 'ee/security_dashboard/components/first_class_group_security_dashboard_vulnerabilities.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/first_class_vulnerability_chart.vue';
import VulnerabilitySeverity from './vulnerability_severity.vue';
import vulnerabilityHistoryQuery from '../graphql/group_vulnerability_history.graphql';

export default {
  components: {
    SecurityDashboardLayout,
    GroupSecurityVulnerabilities,
    VulnerabilitySeverity,
    VulnerabilityChart,
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
    groupFullPath: {
      type: String,
      required: true,
    },
    vulnerableProjectsEndpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      filters: {},
      projects: [],
      vulnerabilityHistoryQuery,
    };
  },
  methods: {
    handleFilterChange(filters) {
      this.filters = filters;
    },
    handleProjectsFetch(projects) {
      this.projects = projects;
    },
  },
};
</script>

<template>
  <security-dashboard-layout>
    <template #sticky>
      <filters :projects="projects" @filterChange="handleFilterChange" />
    </template>
    <group-security-vulnerabilities
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
      :group-full-path="groupFullPath"
      :filters="filters"
      @projectFetch="handleProjectsFetch"
    />
    <template #aside>
      <vulnerability-chart
        :query="vulnerabilityHistoryQuery"
        :group-full-path="groupFullPath"
        class="mb-4"
      />
      <vulnerability-severity :endpoint="vulnerableProjectsEndpoint" />
    </template>
  </security-dashboard-layout>
</template>
