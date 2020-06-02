<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlLoadingIcon, GlButton, GlEmptyState, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import InstanceSecurityVulnerabilities from './first_class_instance_security_dashboard_vulnerabilities.vue';
import VulnerabilitySeverity from 'ee/security_dashboard/components/vulnerability_severity.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/first_class_vulnerability_chart.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import ProjectManager from './project_manager.vue';
import CsvExportButton from './csv_export_button.vue';
import vulnerabilityHistoryQuery from '../graphql/instance_vulnerability_history.graphql';

export default {
  components: {
    ProjectManager,
    CsvExportButton,
    SecurityDashboardLayout,
    InstanceSecurityVulnerabilities,
    VulnerabilitySeverity,
    VulnerabilityChart,
    Filters,
    GlEmptyState,
    GlLoadingIcon,
    GlButton,
    GlLink,
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
    projectAddEndpoint: {
      type: String,
      required: true,
    },
    projectListEndpoint: {
      type: String,
      required: true,
    },

    vulnerabilitiesExportEndpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      filters: {},
      graphqlProjectList: [], // TODO: Rename me to projects once we back the project selector with GraphQL as well
      showProjectSelector: false,
      vulnerabilityHistoryQuery,
    };
  },
  computed: {
    ...mapState('projectSelector', ['projects']),
    ...mapGetters('projectSelector', ['isUpdatingProjects']),
    hasProjectsData() {
      return !this.isUpdatingProjects && this.projects.length > 0;
    },
    shouldShowDashboard() {
      return this.hasProjectsData && !this.showProjectSelector;
    },
    shouldShowEmptyState() {
      return !this.hasProjectsData && !this.showProjectSelector && !this.isUpdatingProjects;
    },
    toggleButtonProps() {
      return this.showProjectSelector
        ? {
            text: s__('SecurityReports|Return to dashboard'),
          }
        : {
            text: s__('SecurityReports|Edit dashboard'),
          };
    },
  },
  created() {
    this.setProjectEndpoints({
      add: this.projectAddEndpoint,
      list: this.projectListEndpoint,
    });

    this.fetchProjects();
  },
  methods: {
    ...mapActions('projectSelector', ['setProjectEndpoints', 'fetchProjects']),
    handleFilterChange(filters) {
      this.filters = filters;
    },
    toggleProjectSelector() {
      this.showProjectSelector = !this.showProjectSelector;
    },
    handleProjectFetch(projects) {
      this.graphqlProjectList = projects;
    },
  },
};
</script>

<template>
  <security-dashboard-layout>
    <template #header>
      <header class="page-title-holder flex-fill d-flex align-items-center">
        <h2 class="page-title flex-grow">{{ s__('SecurityReports|Security Dashboard') }}</h2>
        <csv-export-button :vulnerabilities-export-endpoint="vulnerabilitiesExportEndpoint" />
        <gl-button
          class="page-title-controls ml-2"
          :variant="toggleButtonProps.variant"
          @click="toggleProjectSelector"
          >{{ toggleButtonProps.text }}</gl-button
        >
      </header>
    </template>
    <template #sticky>
      <filters
        v-if="shouldShowDashboard"
        :projects="graphqlProjectList"
        @filterChange="handleFilterChange"
        @projectFetch="handleProjectFetch"
      />
    </template>
    <instance-security-vulnerabilities
      v-if="shouldShowDashboard"
      :projects="projects"
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
      :filters="filters"
      @projectFetch="handleProjectFetch"
    />
    <gl-empty-state
      v-else-if="shouldShowEmptyState"
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
        }}</gl-link>
      </template>
      <template #actions>
        <gl-button variant="success" @click="toggleProjectSelector">
          {{ s__('SecurityReports|Add projects') }}
        </gl-button>
      </template>
    </gl-empty-state>
    <div v-else class="d-flex justify-content-center">
      <project-manager v-if="showProjectSelector" />
      <gl-loading-icon v-else size="lg" class="mt-4" />
    </div>
    <template #aside>
      <vulnerability-chart
        v-if="shouldShowDashboard"
        :query="vulnerabilityHistoryQuery"
        class="mb-4"
      />
      <vulnerability-severity v-if="shouldShowDashboard" :endpoint="vulnerableProjectsEndpoint" />
    </template>
  </security-dashboard-layout>
</template>
