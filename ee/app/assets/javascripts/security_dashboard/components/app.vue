<script>
import { isUndefined } from 'underscore';
import { mapActions, mapState, mapGetters } from 'vuex';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import VulnerabilityList from 'ee/vulnerabilities/components/vulnerability_list.vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import Filters from './filters.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';
import VulnerabilityChart from './vulnerability_chart.vue';
import VulnerabilityCountList from './vulnerability_count_list.vue';
import VulnerabilitySeverity from './vulnerability_severity.vue';
import LoadingError from './loading_error.vue';
import { DASHBOARD_TYPES } from '../store/constants';

export default {
  name: 'SecurityDashboardApp',
  components: {
    Filters,
    IssueModal,
    LoadingError,
    PaginationLinks,
    SecurityDashboardTable,
    VulnerabilityChart,
    VulnerabilityCountList,
    VulnerabilityList,
    VulnerabilitySeverity,
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
    vulnerableProjectsEndpoint: {
      type: String,
      required: false,
      default: '',
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
    loadingErrorIllustrations: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    ...mapState(['dashboardType']),
    ...mapState('vulnerabilities', [
      'isLoadingVulnerabilities',
      'loadingVulnerabilitiesErrorCode',
      'modal',
      'pageInfo',
      'vulnerabilities',
    ]),
    ...mapGetters('filters', ['activeFilters']),
    ...mapGetters('vulnerabilities', ['loadingVulnerabilitiesFailedWithRecognizedErrorCode']),
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
    shouldShowAside() {
      return this.shouldShowChart || this.shouldShowVulnerabilitySeverities;
    },
    shouldShowChart() {
      return Boolean(this.vulnerabilitiesHistoryEndpoint);
    },
    shouldShowVulnerabilitySeverities() {
      return Boolean(this.vulnerableProjectsEndpoint);
    },
    shouldShowCountList() {
      return this.isLockedToProject && Boolean(this.vulnerabilitiesCountEndpoint);
    },
    shouldUseFirstClassVulns() {
      const { dashboardType } = this;
      return Boolean(
        gon?.features?.firstClassVulnerabilities &&
          (dashboardType === DASHBOARD_TYPES.PROJECT ||
            dashboardType === DASHBOARD_TYPES.GROUP ||
            dashboardType === DASHBOARD_TYPES.INSTANCE),
      );
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
    this.setHideDismissedToggleInitialState();
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.setVulnerabilitiesCountEndpoint(this.vulnerabilitiesCountEndpoint);
    this.setVulnerabilitiesHistoryEndpoint(this.vulnerabilitiesHistoryEndpoint);
    this.fetchVulnerabilitiesCount(this.activeFilters);
    this.fetchVulnerabilitiesHistory(this.activeFilters);
    this.fetchPage(this.pageInfo.page);
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
    fetchPage(page) {
      this.fetchVulnerabilities({ ...this.activeFilters, page });
    },
  },
};
</script>

<template>
  <section>
    <loading-error
      v-if="loadingVulnerabilitiesFailedWithRecognizedErrorCode"
      :error-code="loadingVulnerabilitiesErrorCode"
      :illustrations="loadingErrorIllustrations"
    />
    <template v-else>
      <header>
        <filters />
      </header>

      <vulnerability-count-list v-if="shouldShowCountList" class="mb-0" />

      <div class="row mt-4">
        <article class="col" :class="{ 'col-xl-7': !isLockedToProject }">
          <template v-if="shouldUseFirstClassVulns">
            <vulnerability-list
              :is-loading="isLoadingVulnerabilities"
              :vulnerabilities="vulnerabilities"
            >
              <template #emptyState>
                <slot name="emptyState"></slot>
              </template>
            </vulnerability-list>
            <pagination-links
              v-if="pageInfo.total > 1"
              class="justify-content-center prepend-top-default"
              :page-info="pageInfo"
              :change="fetchPage"
            />
          </template>
          <security-dashboard-table v-else>
            <template #emptyState>
              <slot name="emptyState"></slot>
            </template>
          </security-dashboard-table>
        </article>

        <aside v-if="shouldShowAside" class="col-xl-5">
          <vulnerability-chart v-if="shouldShowChart" class="mb-3" />
          <vulnerability-severity
            v-if="shouldShowVulnerabilitySeverities"
            :endpoint="vulnerableProjectsEndpoint"
          />
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
    </template>
  </section>
</template>
