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
  computed: {
    ...mapState('vulnerabilities', ['modal', 'pageInfo']),
    ...mapState('projects', ['projects']),
    ...mapGetters('filters', ['activeFilters']),
    canCreateIssue() {
      const path = this.vulnerability.create_vulnerability_feedback_issue_path;
      return Boolean(path);
    },
    canCreateMergeRequest() {
      const path = this.vulnerability.create_vulnerability_feedback_merge_request_path;
      return Boolean(path);
    },
    canDismissVulnerability() {
      const path = this.vulnerability.create_vulnerability_feedback_dismissal_path;
      return Boolean(path);
    },
    vulnerability() {
      return this.modal.vulnerability;
    },
  },
  created() {
    this.setProjectsEndpoint(this.projectsEndpoint);
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.setVulnerabilitiesCountEndpoint(this.vulnerabilitiesCountEndpoint);
    this.setVulnerabilitiesHistoryEndpoint(this.vulnerabilitiesHistoryEndpoint);
    this.fetchVulnerabilities({ ...this.activeFilters, page: this.pageInfo.page });
    this.fetchVulnerabilitiesCount(this.activeFilters);
    this.fetchVulnerabilitiesHistory(this.activeFilters);
    this.fetchProjects();
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'closeDismissalCommentBox',
      'createIssue',
      'createMergeRequest',
      'dismissVulnerability',
      'fetchVulnerabilities',
      'fetchVulnerabilitiesCount',
      'fetchVulnerabilitiesHistory',
      'openDismissalCommentBox',
      'setVulnerabilitiesCountEndpoint',
      'setVulnerabilitiesEndpoint',
      'setVulnerabilitiesHistoryEndpoint',
      'undoDismiss',
    ]),
    ...mapActions('projects', ['setProjectsEndpoint', 'fetchProjects']),
  },
};
</script>

<template>
  <div>
    <filters />
    <vulnerability-count-list />

    <vulnerability-chart />

    <security-dashboard-table
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
    />

    <issue-modal
      :modal="modal"
      :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
      :can-create-issue="canCreateIssue"
      :can-create-merge-request="canCreateMergeRequest"
      :can-dismiss-vulnerability="canDismissVulnerability"
      @closeDismissalCommentBox="closeDismissalCommentBox()"
      @createMergeRequest="createMergeRequest({ vulnerability })"
      @createNewIssue="createIssue({ vulnerability })"
      @dismissVulnerability="dismissVulnerability({ vulnerability, comment: $event })"
      @openDismissalCommentBox="openDismissalCommentBox()"
      @revertDismissVulnerability="undoDismiss({ vulnerability })"
    />
  </div>
</template>
