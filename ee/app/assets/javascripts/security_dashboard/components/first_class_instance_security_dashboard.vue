<script>
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import InstanceSecurityVulnerabilities from './first_class_instance_security_dashboard_vulnerabilities.vue';

export default {
  components: {
    SecurityDashboardLayout,
    InstanceSecurityVulnerabilities,
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
  },
};
</script>

<template>
  <security-dashboard-layout>
    <instance-security-vulnerabilities
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
    />
  </security-dashboard-layout>
</template>
