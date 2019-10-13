<script>
import { mapActions } from 'vuex';
import SecurityDashboard from './app.vue';

export default {
  name: 'GroupSecurityDashboard',
  components: {
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
    projectsEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilitiesEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilitiesCountEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilitiesHistoryEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: true,
    },
  },
  created() {
    this.setProjectsEndpoint(this.projectsEndpoint);
    this.fetchProjects();
  },
  methods: {
    ...mapActions('projects', ['setProjectsEndpoint', 'fetchProjects']),
  },
};
</script>

<template>
  <security-dashboard
    :dashboard-documentation="dashboardDocumentation"
    :empty-state-svg-path="emptyStateSvgPath"
    :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
    :vulnerabilities-count-endpoint="vulnerabilitiesCountEndpoint"
    :vulnerabilities-history-endpoint="vulnerabilitiesHistoryEndpoint"
    :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
  />
</template>
