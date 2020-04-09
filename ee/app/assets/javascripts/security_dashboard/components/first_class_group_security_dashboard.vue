<script>
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import GroupSecurityVulnerabilities from './first_class_group_security_dashboard_vulnerabilities.vue';
import VulnerabilitySeverity from './vulnerability_severity.vue';

export default {
  components: {
    SecurityDashboardLayout,
    GroupSecurityVulnerabilities,
    VulnerabilitySeverity,
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
};
</script>

<template>
  <security-dashboard-layout>
    <group-security-vulnerabilities
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
      :group-full-path="groupFullPath"
    />
    <template #aside>
      <vulnerability-severity :endpoint="vulnerableProjectsEndpoint" />
    </template>
  </security-dashboard-layout>
</template>
