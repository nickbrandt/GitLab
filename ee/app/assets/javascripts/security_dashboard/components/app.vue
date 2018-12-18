<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import Filters from './filters.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';
import VulnerabilityChart from './vulnerability_chart.vue';
import VulnerabilityCountList from './vulnerability_count_list.vue';

export default {
  name: 'SecurityDashboardApp',
  components: {
    Filters,
    IssueModal,
    SecurityDashboardTable,
    VulnerabilityChart,
    VulnerabilityCountList,
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
  computed: {
    ...mapState('vulnerabilities', ['modal']),
    ...mapGetters('filters', ['activeFilters']),
  },
  created() {
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.setVulnerabilitiesCountEndpoint(this.vulnerabilitiesCountEndpoint);
    this.setVulnerabilitiesHistoryEndpoint(this.vulnerabilitiesHistoryEndpoint);
    this.fetchVulnerabilitiesCount();
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'createIssue',
      'dismissVulnerability',
      'fetchVulnerabilities',
      'fetchVulnerabilitiesCount',
      'fetchVulnerabilitiesHistory',
      'revertDismissal',
      'setVulnerabilitiesCountEndpoint',
      'setVulnerabilitiesEndpoint',
      'setVulnerabilitiesHistoryEndpoint',
    ]),
    filterChange() {
      this.fetchVulnerabilities(this.activeFilters);
      this.fetchVulnerabilitiesCount(this.activeFilters);
      this.fetchVulnerabilitiesHistory(this.activeFilters);
    },
  },
};
</script>

<template>
  <div>
    <filters :dashboard-documentation="dashboardDocumentation" @change="filterChange" />
    <vulnerability-count-list />
    <h4 class="my-4">{{ __('Vulnerability Chart') }}</h4>
    <vulnerability-chart />
    <h4 class="my-4">{{ __('Vulnerability List') }}</h4>
    <security-dashboard-table
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
    />
    <issue-modal
      :modal="modal"
      :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
      :can-create-issue-permission="true"
      :can-create-feedback-permission="true"
      @createNewIssue="createIssue({ vulnerability: modal.vulnerability });"
      @dismissIssue="dismissVulnerability({ vulnerability: modal.vulnerability });"
      @revertDismissIssue="revertDismissal({ vulnerability: modal.vulnerability });"
    />
  </div>
</template>
