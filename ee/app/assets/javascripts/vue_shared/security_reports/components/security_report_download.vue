<script>
import SecurityReportDownloadDropdown from './components/security_report_download_dropdown.vue';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
  reportTypeToSecurityReportTypeEnum,
} from './constants';
import securityReportDownloadPathsQuery from './queries/security_report_download_paths.query.graphql';
import { extractSecurityReportArtifacts } from './utils';

export default {
  store,
  components: {
    SecurityReportDownloadDropdown,
  },
  props: {
    targetProjectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    mrIid: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  apollo: {
    reportArtifacts: {
      query: securityReportDownloadPathsQuery,
      variables() {
        return {
          projectPath: this.targetProjectFullPath,
          iid: String(this.mrIid),
          reportTypes: this.$options.reportTypes.map(
            reportType => reportTypeToSecurityReportTypeEnum[reportType],
          ),
        };
      },
      skip() {
        return !this.canShowDownloads;
      },
      update(data) {
        return extractSecurityReportArtifacts(this.$options.reportTypes, data);
      },
      error(error) {
        this.showError(error);
      },
      result({ loading }) {
        if (loading) {
          return;
        }

        // Query has completed, so populate the availableSecurityReports.
        this.onCheckingAvailableSecurityReports(
          this.reportArtifacts.map(({ reportType }) => reportType),
        );
      },
    },
  },
  computed: {
    ...mapGetters(['groupedSummaryText', 'summaryStatus']),
    canShowDownloads() {
      return this.glFeatures.coreSecurityMrWidgetDownloads;
    },
    shouldShowDownloadGuidance() {
      return !this.canShowDownloads && this.summaryStatus !== LOADING;
    },
    scansHaveRunMessage() {
      return this.canShowDownloads
        ? this.$options.i18n.scansHaveRun
        : this.$options.i18n.scansHaveRunWithDownloadGuidance;
    },
  },
  created() {
    if (!this.canShowDownloads) {
      this.checkAvailableSecurityReports(this.$options.reportTypes)
        .then(availableSecurityReports => {
          this.onCheckingAvailableSecurityReports(Array.from(availableSecurityReports));
        })
        .catch(this.showError);
    }    
  }
}
</script>

<template v-if="canShowDownloads" #action-buttons>
  <security-report-download-dropdown
    :artifacts="reportArtifacts"
    :loading="$apollo.queries.reportArtifacts.loading"
  />
</template>