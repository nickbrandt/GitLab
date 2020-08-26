<script>
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import VulnerabilitySeverities from 'ee/security_dashboard/components/first_class_vulnerability_severities.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/first_class_vulnerability_chart.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import projectsQuery from 'ee/security_dashboard/graphql/get_instance_security_dashboard_projects.query.graphql';
import InstanceSecurityVulnerabilities from './first_class_instance_security_dashboard_vulnerabilities.vue';
import { __ } from '~/locale';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import CsvExportButton from './csv_export_button.vue';
import vulnerabilityHistoryQuery from '../graphql/instance_vulnerability_history.query.graphql';
import vulnerabilityGradesQuery from '../graphql/instance_vulnerability_grades.query.graphql';
import DashboardNotConfigured from './empty_states/instance_dashboard_not_configured.vue';

export default {
  components: {
    CsvExportButton,
    SecurityDashboardLayout,
    InstanceSecurityVulnerabilities,
    VulnerabilitySeverities,
    VulnerabilityChart,
    Filters,
    DashboardNotConfigured,
  },
  props: {
    vulnerabilitiesExportEndpoint: {
      type: String,
      required: true,
    },
  },
  apollo: {
    projects: {
      query: projectsQuery,
      update(data) {
        return data.instanceSecurityDashboard.projects.nodes;
      },
      error() {
        createFlash(__('Something went wrong, unable to get projects'));
      },
    },
  },
  data() {
    return {
      filters: {},
      vulnerabilityHistoryQuery,
      vulnerabilityGradesQuery,
      projects: [],
    };
  },
  computed: {
    isLoadingProjects() {
      return this.$apollo.queries.projects.loading;
    },
    hasProjectsData() {
      return !this.isLoadingProjects && this.projects.length > 0;
    },
    shouldShowDashboard() {
      return this.hasProjectsData;
    },
    shouldShowEmptyState() {
      return !this.isLoadingProjects && this.projects.length === 0;
    },
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
        <h2 class="page-title flex-grow">{{ s__('SecurityReports|Security Dashboard') }}</h2>
        <csv-export-button
          v-if="shouldShowDashboard"
          :vulnerabilities-export-endpoint="vulnerabilitiesExportEndpoint"
        />
      </header>
    </template>
    <template #sticky>
      <filters v-if="shouldShowDashboard" :projects="projects" @filterChange="handleFilterChange" />
    </template>
    <instance-security-vulnerabilities
      v-if="shouldShowDashboard"
      :projects="projects"
      :filters="filters"
    />
    <dashboard-not-configured v-else-if="shouldShowEmptyState" />
    <template #aside>
      <template v-if="shouldShowDashboard">
        <vulnerability-chart :query="vulnerabilityHistoryQuery" class="mb-4" />
        <vulnerability-severities :query="vulnerabilityGradesQuery" />
      </template>
    </template>
  </security-dashboard-layout>
</template>
