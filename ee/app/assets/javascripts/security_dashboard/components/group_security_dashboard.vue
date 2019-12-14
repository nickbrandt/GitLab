<script>
import { mapActions } from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import SecurityDashboard from './app.vue';

export default {
  name: 'GroupSecurityDashboard',
  components: {
    GlEmptyState,
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
    vulnerableProjectsEndpoint: {
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
    :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
    :vulnerabilities-count-endpoint="vulnerabilitiesCountEndpoint"
    :vulnerabilities-history-endpoint="vulnerabilitiesHistoryEndpoint"
    :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
    :vulnerable-projects-endpoint="vulnerableProjectsEndpoint"
  >
    <template #emptyState>
      <gl-empty-state
        :title="s__(`No vulnerabilities found for this group`)"
        :svg-path="emptyStateSvgPath"
        :description="
          s__(
            `While it's rare to have no vulnerabilities for your group, it can happen. In any event, we ask that you double check your settings to make sure you've set up your dashboard correctly.`,
          )
        "
        :primary-button-link="dashboardDocumentation"
        :primary-button-text="s__('Security Reports|Learn more about setting up your dashboard')"
      />
    </template>
  </security-dashboard>
</template>
