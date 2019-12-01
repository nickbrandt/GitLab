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
    vulnerabilitiesEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilitiesCountEndpoint: {
      type: String,
      required: false,
      default: '',
    },
    vulnerabilitiesHistoryEndpoint: {
      type: String,
      required: false,
      default: '',
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: true,
    },
    lockToProject: {
      type: Object,
      required: false,
      default: null,
      validator: project => !isUndefined(project.id),
    },
    pipelineId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapState('vulnerabilities', ['modal', 'pageInfo']),
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
    shouldShowChart() {
      return Boolean(this.vulnerabilitiesHistoryEndpoint);
    },
    shouldShowCountList() {
      return this.isLockedToProject && Boolean(this.vulnerabilitiesCountEndpoint);
    },
    showHideDismissedToggle() {
      return Boolean(gon.features && gon.features.hideDismissedVulnerabilities);
    },
  },
  watch: {
    'pageInfo.total': 'emitVulnerabilitiesCountChanged',
  },
  created() {
    if (this.isLockedToProject) {
      this.lockFilter({
        filterId: 'project_id',
        optionId: this.lockToProject.id,
      });
    }
    this.setPipelineId(this.pipelineId);
    if (this.showHideDismissedToggle) {
      this.setHideDismissedToggleInitialState();
    }
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.setVulnerabilitiesCountEndpoint(this.vulnerabilitiesCountEndpoint);
    this.setVulnerabilitiesHistoryEndpoint(this.vulnerabilitiesHistoryEndpoint);
    this.fetchVulnerabilities({ ...this.activeFilters, page: this.pageInfo.page });
    this.fetchVulnerabilitiesCount(this.activeFilters);
    this.fetchVulnerabilitiesHistory(this.activeFilters);
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
      'setPipelineId',
      'setVulnerabilitiesCountEndpoint',
      'setVulnerabilitiesEndpoint',
      'setVulnerabilitiesHistoryEndpoint',
      'showDismissalDeleteButtons',
      'hideDismissalDeleteButtons',
      'undoDismiss',
      'downloadPatch',
    ]),
    ...mapActions('filters', ['lockFilter', 'setHideDismissedToggleInitialState']),
    emitVulnerabilitiesCountChanged(count) {
      this.$emit('vulnerabilitiesCountChanged', count);
    },
  },
};
</script>

<template>
  <section>
    <header>
      <filters :show-hide-dismissed-toggle="showHideDismissedToggle" />
    </header>

    <vulnerability-count-list v-if="shouldShowCountList" class="mb-0" />

    <div class="row mt-4">
      <article class="col" :class="{ 'col-xl-7': !isLockedToProject }">
        <security-dashboard-table>
          <template #emptyState>
            <slot name="emptyState"></slot>
          </template>
        </security-dashboard-table>
      </article>

      <aside v-if="shouldShowChart" class="col-xl-5">
        <vulnerability-chart />
      </aside>
    </div>

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
  </section>
</template>
