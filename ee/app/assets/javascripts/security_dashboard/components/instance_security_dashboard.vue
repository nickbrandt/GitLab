<script>
import { mapActions, mapState } from 'vuex';
import { GlDeprecatedButton, GlEmptyState, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import ProjectManager from './project_manager.vue';
import SecurityDashboard from './security_dashboard_vuex.vue';

export default {
  name: 'InstanceSecurityDashboard',
  components: {
    GlDeprecatedButton,
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    ProjectManager,
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
    emptyDashboardStateSvgPath: {
      type: String,
      required: true,
    },
    projectAddEndpoint: {
      type: String,
      required: true,
    },
    projectListEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilitiesEndpoint: {
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
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isInitialized: false,
      showProjectSelector: false,
    };
  },
  computed: {
    ...mapState('projectSelector', ['projects']),
    toggleButtonProps() {
      return this.showProjectSelector
        ? {
            variant: 'success',
            text: s__('SecurityReports|Return to dashboard'),
          }
        : {
            variant: 'secondary',
            text: s__('SecurityReports|Edit dashboard'),
          };
    },
    shouldShowEmptyState() {
      return this.isInitialized && this.projects.length === 0;
    },
  },
  created() {
    this.setProjectEndpoints({
      add: this.projectAddEndpoint,
      list: this.projectListEndpoint,
    });
    this.fetchProjects()
      // Failure to fetch projects will be handled in the store, so do nothing here.
      .catch(() => {})
      .finally(() => {
        this.isInitialized = true;
      });
  },
  methods: {
    ...mapActions('projectSelector', ['setProjectEndpoints', 'fetchProjects']),
    toggleProjectSelector() {
      this.showProjectSelector = !this.showProjectSelector;
    },
  },
};
</script>

<template>
  <article>
    <header class="page-title-holder flex-fill d-flex align-items-center">
      <h2 class="page-title">{{ s__('SecurityReports|Security Dashboard') }}</h2>
      <gl-deprecated-button
        v-if="isInitialized"
        class="page-title-controls js-project-selector-toggle"
        :variant="toggleButtonProps.variant"
        @click="toggleProjectSelector"
        v-text="toggleButtonProps.text"
      />
    </header>

    <template v-if="isInitialized">
      <project-manager v-if="showProjectSelector" />

      <template v-else>
        <gl-empty-state
          v-if="shouldShowEmptyState"
          :title="s__('SecurityReports|Add a project to your dashboard')"
          :svg-path="emptyStateSvgPath"
        >
          <template #description>
            {{
              s__(
                'SecurityReports|The security dashboard displays the latest security findings for projects you wish to monitor. Select "Edit dashboard" to add and remove projects.',
              )
            }}
            <gl-link :href="dashboardDocumentation">{{
              s__('SecurityReports|More information')
            }}</gl-link
            >.
          </template>
          <template #actions>
            <gl-deprecated-button variant="success" @click="toggleProjectSelector">
              {{ s__('SecurityReports|Add projects') }}
            </gl-deprecated-button>
          </template>
        </gl-empty-state>

        <security-dashboard
          v-else
          :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
          :vulnerabilities-history-endpoint="vulnerabilitiesHistoryEndpoint"
          :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
          :vulnerable-projects-endpoint="vulnerableProjectsEndpoint"
        />
      </template>
    </template>

    <gl-loading-icon v-else size="md" class="mt-4" />
  </article>
</template>
