<script>
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import ProjectVulnerabilitiesApp from 'ee/vulnerabilities/components/project_vulnerabilities_app.vue';

export default {
  components: {
    SecurityDashboardLayout,
    ProjectVulnerabilitiesApp,
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
};
</script>

<template>
  <security-dashboard-layout>
    <project-vulnerabilities-app
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
      :project-full-path="projectFullPath"
    />
  </security-dashboard-layout>
</template>
