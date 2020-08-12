<script>
import { GlLoadingIcon } from '@gitlab/ui';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import GroupSecurityVulnerabilities from 'ee/security_dashboard/components/first_class_group_security_dashboard_vulnerabilities.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import CsvExportButton from './csv_export_button.vue';
import DashboardNotConfigured from './empty_states/group_dashboard_not_configured.vue';

export default {
  components: {
    SecurityDashboardLayout,
    GroupSecurityVulnerabilities,
    Filters,
    CsvExportButton,
    DashboardNotConfigured,
    GlLoadingIcon,
  },
  props: {
    groupFullPath: {
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
      projects: [],
      projectsWereFetched: false,
    };
  },
  computed: {
    isNotYetConfigured() {
      return this.projects.length === 0 && this.projectsWereFetched;
    },
  },
  methods: {
    handleFilterChange(filters) {
      this.filters = filters;
    },
    handleProjectsFetch(projects) {
      this.projects = projects;
      this.projectsWereFetched = true;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="!projectsWereFetched" size="lg" class="gl-mt-6" />
    <dashboard-not-configured v-if="isNotYetConfigured" />
    <security-dashboard-layout v-else :class="{ 'gl-display-none': !projectsWereFetched }">
      <template #header>
        <header class="page-title-holder flex-fill d-flex align-items-center">
          <h2 class="page-title flex-grow">
            {{ s__('SecurityReports|Vulnerability Report') }}
          </h2>
          <csv-export-button :vulnerabilities-export-endpoint="vulnerabilitiesExportEndpoint" />
        </header>
      </template>
      <template #sticky>
        <filters :projects="projects" @filterChange="handleFilterChange" />
      </template>
      <group-security-vulnerabilities
        :group-full-path="groupFullPath"
        :filters="filters"
        @projectFetch="handleProjectsFetch"
      />
    </security-dashboard-layout>
  </div>
</template>
