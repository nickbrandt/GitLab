<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import ReportSection from '~/reports/components/report_section.vue';
import SummaryRow from '~/reports/components/summary_row.vue';
import IssuesList from '~/reports/components/issues_list.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { componentNames } from 'ee/reports/components/issue_body';
import IssueModal from './components/modal.vue';
import securityReportsMixin from './mixins/security_report_mixin';
import createStore from './store';

export default {
  store: createStore(),
  components: {
    ReportSection,
    SummaryRow,
    IssuesList,
    IssueModal,
    Icon,
  },
  mixins: [securityReportsMixin],
  props: {
    headBlobPath: {
      type: String,
      required: true,
    },
    baseBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    sourceBranch: {
      type: String,
      required: false,
      default: null,
    },
    sastHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    sastBasePath: {
      type: String,
      required: false,
      default: null,
    },
    dastHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    dastBasePath: {
      type: String,
      required: false,
      default: null,
    },
    sastContainerHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    sastContainerBasePath: {
      type: String,
      required: false,
      default: null,
    },
    dependencyScanningHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    dependencyScanningBasePath: {
      type: String,
      required: false,
      default: null,
    },
    sastHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    sastContainerHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    dastHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    dependencyScanningHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    vulnerabilityFeedbackPath: {
      type: String,
      required: false,
      default: '',
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    createVulnerabilityFeedbackIssuePath: {
      type: String,
      required: false,
      default: '',
    },
    createVulnerabilityFeedbackMergeRequestPath: {
      type: String,
      required: false,
      default: '',
    },
    createVulnerabilityFeedbackDismissalPath: {
      type: String,
      required: false,
      default: '',
    },
    pipelineId: {
      type: Number,
      required: false,
      default: null,
    },
    pipelinePath: {
      type: String,
      required: false,
      default: undefined,
    },
    canDismissVulnerability: {
      type: Boolean,
      required: true,
    },
    canCreateMergeRequest: {
      type: Boolean,
      required: true,
    },
    canCreateIssue: {
      type: Boolean,
      required: true,
    },
  },
  componentNames,
  computed: {
    ...mapState([
      'sast',
      'sastContainer',
      'dast',
      'dependencyScanning',
      'summaryCounts',
      'modal',
      'canCreateIssuePermission',
      'canCreateFeedbackPermission',
    ]),
    ...mapGetters([
      'groupedSummaryText',
      'summaryStatus',
      'groupedSastContainerText',
      'groupedDastText',
      'groupedDependencyText',
      'sastContainerStatusIcon',
      'dastStatusIcon',
      'dependencyScanningStatusIcon',
    ]),
    ...mapGetters('sast', ['groupedSastText', 'sastStatusIcon']),
    securityTab() {
      return `${this.pipelinePath}/security`;
    },
  },

  created() {
    this.setHeadBlobPath(this.headBlobPath);
    this.setBaseBlobPath(this.baseBlobPath);
    this.setSourceBranch(this.sourceBranch);

    this.setVulnerabilityFeedbackPath(this.vulnerabilityFeedbackPath);
    this.setVulnerabilityFeedbackHelpPath(this.vulnerabilityFeedbackHelpPath);
    this.setCreateVulnerabilityFeedbackIssuePath(this.createVulnerabilityFeedbackIssuePath);
    this.setCreateVulnerabilityFeedbackMergeRequestPath(
      this.createVulnerabilityFeedbackMergeRequestPath,
    );
    this.setCreateVulnerabilityFeedbackDismissalPath(this.createVulnerabilityFeedbackDismissalPath);
    this.setPipelineId(this.pipelineId);

    this.setCanCreateIssuePermission(this.canCreateIssue);
    this.setCanCreateFeedbackPermission(this.canCreateFeedback);

    if (this.sastHeadPath) {
      this.setSastHeadPath(this.sastHeadPath);

      if (this.sastBasePath) {
        this.setSastBasePath(this.sastBasePath);
      }
      this.fetchSastReports();
    }

    if (this.sastContainerHeadPath) {
      this.setSastContainerHeadPath(this.sastContainerHeadPath);

      if (this.sastContainerBasePath) {
        this.setSastContainerBasePath(this.sastContainerBasePath);
      }
      this.fetchSastContainerReports();
    }

    if (this.dastHeadPath) {
      this.setDastHeadPath(this.dastHeadPath);

      if (this.dastBasePath) {
        this.setDastBasePath(this.dastBasePath);
      }
      this.fetchDastReports();
    }

    if (this.dependencyScanningHeadPath) {
      this.setDependencyScanningHeadPath(this.dependencyScanningHeadPath);

      if (this.dependencyScanningBasePath) {
        this.setDependencyScanningBasePath(this.dependencyScanningBasePath);
      }
      this.fetchDependencyScanningReports();
    }
  },
  methods: {
    ...mapActions([
      'setAppType',
      'setHeadBlobPath',
      'setBaseBlobPath',
      'setSourceBranch',
      'setSastContainerHeadPath',
      'setSastContainerBasePath',
      'setDastHeadPath',
      'setDastBasePath',
      'setDependencyScanningHeadPath',
      'setDependencyScanningBasePath',
      'fetchSastContainerReports',
      'fetchDastReports',
      'fetchDependencyScanningReports',
      'setVulnerabilityFeedbackPath',
      'setVulnerabilityFeedbackHelpPath',
      'setCreateVulnerabilityFeedbackIssuePath',
      'setCreateVulnerabilityFeedbackMergeRequestPath',
      'setCreateVulnerabilityFeedbackDismissalPath',
      'setPipelineId',
      'setCanCreateIssuePermission',
      'setCanCreateFeedbackPermission',
      'dismissVulnerability',
      'revertDismissVulnerability',
      'createNewIssue',
      'createMergeRequest',
      'openDismissalCommentBox',
      'closeDismissalCommentBox',
      'downloadPatch',
      'addDismissalComment',
      'deleteDismissalComment',
      'showDismissalDeleteButtons',
      'hideDismissalDeleteButtons',
    ]),
    ...mapActions('sast', {
      setSastHeadPath: 'setHeadPath',
      setSastBasePath: 'setBasePath',
      fetchSastReports: 'fetchReports',
    }),
  },
};
</script>
<template>
  <report-section
    :status="summaryStatus"
    :success-text="groupedSummaryText"
    :loading-text="groupedSummaryText"
    :error-text="groupedSummaryText"
    :has-issues="true"
    class="mr-widget-border-top grouped-security-reports mr-report"
    data-qa-selector="vulnerability_report_grouped"
  >
    <div v-if="pipelinePath" slot="actionButtons">
      <a
        :href="securityTab"
        target="_blank"
        class="btn btn-default btn-sm float-right append-right-default"
      >
        <span>{{ s__('ciReport|View full report') }}</span> <icon :size="16" name="external-link" />
      </a>
    </div>

    <div slot="body" class="mr-widget-grouped-section report-block">
      <template v-if="sastHeadPath">
        <summary-row
          :summary="groupedSastText"
          :status-icon="sastStatusIcon"
          :popover-options="sastPopover"
          class="js-sast-widget"
        />

        <issues-list
          v-if="sast.newIssues.length || sast.resolvedIssues.length"
          :unresolved-issues="sast.newIssues"
          :resolved-issues="sast.resolvedIssues"
          :all-issues="sast.allIssues"
          :component="$options.componentNames.SastIssueBody"
          class="js-sast-issue-list report-block-group-list"
        />
      </template>

      <template v-if="dependencyScanningHeadPath">
        <summary-row
          :summary="groupedDependencyText"
          :status-icon="dependencyScanningStatusIcon"
          :popover-options="dependencyScanningPopover"
          class="js-dependency-scanning-widget"
        />

        <issues-list
          v-if="dependencyScanning.newIssues.length || dependencyScanning.resolvedIssues.length"
          :unresolved-issues="dependencyScanning.newIssues"
          :resolved-issues="dependencyScanning.resolvedIssues"
          :component="$options.componentNames.SastIssueBody"
          class="js-dss-issue-list report-block-group-list"
        />
      </template>

      <template v-if="sastContainerHeadPath">
        <summary-row
          :summary="groupedSastContainerText"
          :status-icon="sastContainerStatusIcon"
          :popover-options="sastContainerPopover"
          class="js-sast-container"
        />

        <issues-list
          v-if="sastContainer.newIssues.length || sastContainer.resolvedIssues.length"
          :unresolved-issues="sastContainer.newIssues"
          :resolved-issues="sastContainer.resolvedIssues"
          :component="$options.componentNames.SastContainerIssueBody"
          class="report-block-group-list"
        />
      </template>

      <template v-if="dastHeadPath">
        <summary-row
          :summary="groupedDastText"
          :status-icon="dastStatusIcon"
          :popover-options="dastPopover"
          class="js-dast-widget"
        />

        <issues-list
          v-if="dast.newIssues.length || dast.resolvedIssues.length"
          :unresolved-issues="dast.newIssues"
          :resolved-issues="dast.resolvedIssues"
          :component="$options.componentNames.DastIssueBody"
          class="report-block-group-list"
        />
      </template>

      <issue-modal
        :modal="modal"
        :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
        :can-create-issue="canCreateIssue"
        :can-create-merge-request="canCreateMergeRequest"
        :can-dismiss-vulnerability="canDismissVulnerability"
        @closeDismissalCommentBox="closeDismissalCommentBox()"
        @createMergeRequest="createMergeRequest"
        @createNewIssue="createNewIssue"
        @dismissVulnerability="dismissVulnerability"
        @openDismissalCommentBox="openDismissalCommentBox()"
        @editVulnerabilityDismissalComment="openDismissalCommentBox()"
        @revertDismissVulnerability="revertDismissVulnerability"
        @downloadPatch="downloadPatch"
        @addDismissalComment="addDismissalComment({ comment: $event })"
        @deleteDismissalComment="deleteDismissalComment"
        @showDismissalDeleteButtons="showDismissalDeleteButtons"
        @hideDismissalDeleteButtons="hideDismissalDeleteButtons"
      />
    </div>
  </report-section>
</template>
