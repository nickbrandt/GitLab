<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { componentNames } from 'ee/reports/components/issue_body';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ReportSection from '~/reports/components/report_section.vue';
import SummaryRow from '~/reports/components/summary_row.vue';
import IssuesList from '~/reports/components/issues_list.vue';
import Icon from '~/vue_shared/components/icon.vue';
import IssueModal from './components/modal.vue';
import securityReportsMixin from './mixins/security_report_mixin';
import createStore from './store';
import { GlSprintf, GlLink } from '@gitlab/ui';
import { mrStates } from '~/mr_popover/constants';

export default {
  store: createStore(),
  components: {
    ReportSection,
    SummaryRow,
    IssuesList,
    IssueModal,
    Icon,
    GlSprintf,
    GlLink,
  },
  mixins: [securityReportsMixin, glFeatureFlagsMixin()],
  props: {
    enabledReports: {
      type: Object,
      required: false,
      default: () => ({}),
    },
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
    targetBranch: {
      type: String,
      required: false,
      default: null,
    },
    sastHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    containerScanningHelpPath: {
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
    secretScanningHelpPath: {
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
    divergedCommitsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    mrState: {
      type: String,
      required: false,
      default: null,
    },
    targetBranchTreePath: {
      type: String,
      required: false,
      default: '',
    },
    newPipelinePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  componentNames,
  computed: {
    ...mapState([
      'sast',
      'containerScanning',
      'dast',
      'dependencyScanning',
      'secretScanning',
      'summaryCounts',
      'modal',
      'isCreatingIssue',
      'isDismissingVulnerability',
      'isCreatingMergeRequest',
    ]),
    ...mapGetters([
      'groupedSummaryText',
      'summaryStatus',
      'groupedContainerScanningText',
      'groupedDastText',
      'groupedDependencyText',
      'groupedSecretScanningText',
      'containerScanningStatusIcon',
      'dastStatusIcon',
      'dependencyScanningStatusIcon',
      'secretScanningStatusIcon',
      'isBaseSecurityReportOutOfDate',
      'canCreateIssue',
      'canCreateMergeRequest',
      'canDismissVulnerability',
    ]),
    ...mapGetters('sast', ['groupedSastText', 'sastStatusIcon']),
    securityTab() {
      return `${this.pipelinePath}/security`;
    },
    hasContainerScanningReports() {
      return this.enabledReports.containerScanning;
    },
    hasDependencyScanningReports() {
      return this.enabledReports.dependencyScanning;
    },
    hasDastReports() {
      return this.enabledReports.dast;
    },
    hasSastReports() {
      return this.enabledReports.sast;
    },
    hasSecretScanningReports() {
      return this.enabledReports.secretScanning;
    },
    isMRActive() {
      return this.mrState !== mrStates.merged && this.mrState !== mrStates.closed;
    },
    isMRBranchOutdated() {
      return this.divergedCommitsCount > 0;
    },
    dastScans() {
      return this.dast.scans.filter(scan => scan.scanned_resources_count > 0);
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

    const sastDiffEndpoint = gl?.mrWidgetData?.sast_comparison_path;

    if (sastDiffEndpoint && this.hasSastReports) {
      this.setSastDiffEndpoint(sastDiffEndpoint);
      this.fetchSastDiff();
    }

    const containerScanningDiffEndpoint = gl?.mrWidgetData?.container_scanning_comparison_path;

    if (containerScanningDiffEndpoint && this.hasContainerScanningReports) {
      this.setContainerScanningDiffEndpoint(containerScanningDiffEndpoint);
      this.fetchContainerScanningDiff();
    }

    const dastDiffEndpoint = gl?.mrWidgetData?.dast_comparison_path;

    if (dastDiffEndpoint && this.hasDastReports) {
      this.setDastDiffEndpoint(dastDiffEndpoint);
      this.fetchDastDiff();
    }

    const dependencyScanningDiffEndpoint = gl?.mrWidgetData?.dependency_scanning_comparison_path;

    if (dependencyScanningDiffEndpoint && this.hasDependencyScanningReports) {
      this.setDependencyScanningDiffEndpoint(dependencyScanningDiffEndpoint);
      this.fetchDependencyScanningDiff();
    }

    const secretScanningDiffEndpoint = gl?.mrWidgetData?.secret_scanning_comparison_path;
    if (secretScanningDiffEndpoint && this.hasSecretScanningReports) {
      this.setSecretScanningDiffEndpoint(secretScanningDiffEndpoint);
      this.fetchSecretScanningDiff();
    }
  },
  methods: {
    ...mapActions([
      'setAppType',
      'setHeadBlobPath',
      'setBaseBlobPath',
      'setSourceBranch',
      'setVulnerabilityFeedbackPath',
      'setVulnerabilityFeedbackHelpPath',
      'setCreateVulnerabilityFeedbackIssuePath',
      'setCreateVulnerabilityFeedbackMergeRequestPath',
      'setCreateVulnerabilityFeedbackDismissalPath',
      'setPipelineId',
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
      'fetchContainerScanningDiff',
      'setContainerScanningDiffEndpoint',
      'fetchDependencyScanningDiff',
      'setDependencyScanningDiffEndpoint',
      'fetchDastDiff',
      'setDastDiffEndpoint',
      'fetchSecretScanningDiff',
      'setSecretScanningDiffEndpoint',
    ]),
    ...mapActions('sast', {
      setSastDiffEndpoint: 'setDiffEndpoint',
      fetchSastDiff: 'fetchDiff',
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
    <template v-if="pipelinePath" #actionButtons>
      <div>
        <a
          :href="securityTab"
          target="_blank"
          class="btn btn-default btn-sm float-right append-right-default"
        >
          <span>{{ s__('ciReport|View full report') }}</span>
          <icon :size="16" name="external-link" />
        </a>
      </div>
    </template>

    <template v-if="isMRActive && isBaseSecurityReportOutOfDate" #subHeading>
      <div class="text-secondary-700 text-1">
        <gl-sprintf
          v-if="isMRBranchOutdated"
          :message="
            __(
              'Security report is out of date. Please update your branch with the latest changes from the target branch (%{targetBranchName})',
            )
          "
        >
          <template #targetBranchName>
            <gl-link class="text-1" :href="targetBranchTreePath">{{ targetBranch }}</gl-link>
          </template>
        </gl-sprintf>

        <gl-sprintf
          v-else
          :message="
            __(
              'Security report is out of date. Run %{newPipelineLinkStart}a new pipeline%{newPipelineLinkEnd} for the target branch (%{targetBranchName})',
            )
          "
        >
          <template #newPipelineLink="{ content }">
            <gl-link class="text-1" :href="`${newPipelinePath}?ref=${targetBranch}`">{{
              content
            }}</gl-link>
          </template>
          <template #targetBranchName>
            <gl-link class="text-1" :href="targetBranchTreePath">{{ targetBranch }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
    </template>

    <template #body>
      <div class="mr-widget-grouped-section report-block">
        <template v-if="hasSastReports">
          <summary-row
            :summary="groupedSastText"
            :status-icon="sastStatusIcon"
            :popover-options="sastPopover"
            class="js-sast-widget"
            data-qa-selector="sast_scan_report"
          />

          <issues-list
            v-if="sast.newIssues.length || sast.resolvedIssues.length"
            :unresolved-issues="sast.newIssues"
            :resolved-issues="sast.resolvedIssues"
            :all-issues="sast.allIssues"
            :component="$options.componentNames.SecurityIssueBody"
            class="js-sast-issue-list report-block-group-list"
          />
        </template>

        <template v-if="hasDependencyScanningReports">
          <summary-row
            :summary="groupedDependencyText"
            :status-icon="dependencyScanningStatusIcon"
            :popover-options="dependencyScanningPopover"
            class="js-dependency-scanning-widget"
            data-qa-selector="dependency_scan_report"
          />

          <issues-list
            v-if="dependencyScanning.newIssues.length || dependencyScanning.resolvedIssues.length"
            :unresolved-issues="dependencyScanning.newIssues"
            :resolved-issues="dependencyScanning.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            class="js-dss-issue-list report-block-group-list"
          />
        </template>

        <template v-if="hasContainerScanningReports">
          <summary-row
            :summary="groupedContainerScanningText"
            :status-icon="containerScanningStatusIcon"
            :popover-options="containerScanningPopover"
            class="js-container-scanning"
            data-qa-selector="container_scan_report"
          />

          <issues-list
            v-if="containerScanning.newIssues.length || containerScanning.resolvedIssues.length"
            :unresolved-issues="containerScanning.newIssues"
            :resolved-issues="containerScanning.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            class="report-block-group-list"
          />
        </template>

        <template v-if="hasDastReports">
          <summary-row
            :summary="groupedDastText"
            :status-icon="dastStatusIcon"
            :popover-options="dastPopover"
            class="js-dast-widget"
            data-qa-selector="dast_scan_report"
          >
            <template v-if="dastScans.length">
              <div class="text-nowrap">
                {{ n__('%d URL scanned', '%d URLs scanned', dastScans[0].scanned_resources_count) }}
              </div>
              <gl-link
                class="ml-2"
                data-qa-selector="dast-ci-job-link"
                :href="dastScans[0].job_path"
              >
                {{ __('View details') }}
              </gl-link>
            </template>
          </summary-row>

          <issues-list
            v-if="dast.newIssues.length || dast.resolvedIssues.length"
            :unresolved-issues="dast.newIssues"
            :resolved-issues="dast.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            class="report-block-group-list"
          />
        </template>

        <template v-if="hasSecretScanningReports">
          <summary-row
            :summary="groupedSecretScanningText"
            :status-icon="secretScanningStatusIcon"
            :popover-options="secretScanningPopover"
            class="js-secret-scanning"
            data-qa-selector="secret_scan_report"
          />

          <issues-list
            v-if="secretScanning.newIssues.length || secretScanning.resolvedIssues.length"
            :unresolved-issues="secretScanning.newIssues"
            :resolved-issues="secretScanning.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            class="report-block-group-list"
          />
        </template>

        <issue-modal
          :modal="modal"
          :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
          :can-create-issue="canCreateIssue"
          :can-create-merge-request="canCreateMergeRequest"
          :can-dismiss-vulnerability="canDismissVulnerability"
          :is-creating-issue="isCreatingIssue"
          :is-dismissing-vulnerability="isDismissingVulnerability"
          :is-creating-merge-request="isCreatingMergeRequest"
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
    </template>
  </report-section>
</template>
