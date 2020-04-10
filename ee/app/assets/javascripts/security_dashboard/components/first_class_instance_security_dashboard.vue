<script>
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import InstanceSecurityVulnerabilities from './first_class_instance_security_dashboard_vulnerabilities.vue';
import VulnerabilitySeverity from 'ee/security_dashboard/components/vulnerability_severity.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';

export default {
  components: {
    SecurityDashboardLayout,
    InstanceSecurityVulnerabilities,
    VulnerabilitySeverity,
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
    vulnerableProjectsEndpoint: {
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
      <header class="page-title-holder flex-fill d-flex align-items-center">
        <h2 class="page-title">{{ s__('SecurityDashboard|Security Dashboard') }}</h2>
      </header>
      <filters @filterChange="handleFilterChange" />
    </template>
    <instance-security-vulnerabilities
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
      :filters="filters"
    />
    <template #aside>
      <vulnerability-severity :endpoint="vulnerableProjectsEndpoint" />
    </template>
  </security-dashboard-layout>
</template>
