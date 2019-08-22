<script>
import { isUndefined } from 'underscore';
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
      required: false,
      default: null,
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
    lockToProject: {
      type: Object,
      required: false,
      default: null,
      validator: project => !isUndefined(project.id) && !isUndefined(project.name),
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
    isLockedToProject() {
      return this.lockToProject !== null;
    },
  },
  created() {
    if (this.isLockedToProject) {
      this.lockFilter({
        filterId: 'project_id',
        optionId: this.lockToProject.id,
      });
    }
    this.setProjectsEndpoint(this.projectsEndpoint);
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.setVulnerabilitiesCountEndpoint(this.vulnerabilitiesCountEndpoint);
    this.setVulnerabilitiesHistoryEndpoint(this.vulnerabilitiesHistoryEndpoint);
    this.fetchVulnerabilities({ ...this.activeFilters, page: this.pageInfo.page });
    this.fetchVulnerabilitiesCount(this.activeFilters);
    this.fetchVulnerabilitiesHistory(this.activeFilters);
    if (!this.isLockedToProject) {
      this.fetchProjects();
    }
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'addDismissalComment',
      'deleteDismissalComment',
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
      'showDismissalDeleteButtons',
      'hideDismissalDeleteButtons',
      'undoDismiss',
      'downloadPatch',
    ]),
    ...mapActions('projects', ['setProjectsEndpoint', 'fetchProjects']),
    ...mapActions('filters', ['lockFilter']),
  },
};
</script>

<template>
  <div>
    <filters />
    <vulnerability-count-list :class="{ 'mb-0': isLockedToProject }" />

    <vulnerability-chart v-if="!isLockedToProject" />

    <h4 v-if="!isLockedToProject" class="my-4">{{ __('Vulnerability List') }}</h4>

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
      @addDismissalComment="addDismissalComment({ vulnerability, comment: $event })"
      @editVulnerabilityDismissalComment="openDismissalCommentBox()"
      @showDismissalDeleteButtons="showDismissalDeleteButtons"
      @hideDismissalDeleteButtons="hideDismissalDeleteButtons"
      @deleteDismissalComment="deleteDismissalComment({ vulnerability })"
      @closeDismissalCommentBox="closeDismissalCommentBox()"
      @createMergeRequest="createMergeRequest({ vulnerability })"
      @createNewIssue="createIssue({ vulnerability })"
      @dismissVulnerability="dismissVulnerability({ vulnerability, comment: $event })"
      @openDismissalCommentBox="openDismissalCommentBox()"
      @revertDismissVulnerability="undoDismiss({ vulnerability })"
      @downloadPatch="downloadPatch({ vulnerability })"
    />
  </div>
</template>
