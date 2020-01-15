<script>
import { mapActions, mapState } from 'vuex';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import { componentNames } from 'ee/reports/components/issue_body';
import ReportSection from '~/reports/components/report_section.vue';
import { n__, s__, sprintf } from '~/locale';

import createStore from './store';

export default {
  store: createStore(),
  components: {
    ReportSection,
  },
  mixins: [reportsMixin],
  componentNames,
  props: {
    codequalityReportDownloadPath: {
      type: String,
      required: true,
    },
    blobPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'isLoadingCodequality',
      'loadingCodequalityFailed',
      'codeQualityIssues',
      'endpoint',
    ]),
    hasCodequalityIssues() {
      return this.codeQualityIssues.length > 0;
    },
    codequalityText() {
      const text = [];
      const { codeQualityIssues } = this;

      if (!codeQualityIssues.length) {
        return s__('ciReport|No code quality issues found');
      } else if (codeQualityIssues.length) {
        return sprintf(s__('ciReport|Found %{issuesWithCount}'), {
          issuesWithCount: n__(
            '%d code quality issue',
            '%d code quality issues',
            codeQualityIssues.length,
          ),
        });
      }

      return text.join('');
    },
    codequalityStatus() {
      return this.checkReportStatus(this.isLoadingCodequality, this.loadingCodequalityFailed);
    },
  },
  created() {
    this.setEndpoint(this.codequalityReportDownloadPath);
    this.setBlobPath(this.blobPath);
    this.fetchReport();
  },
  methods: {
    ...mapActions(['setEndpoint', 'setBlobPath', 'fetchReport']),
    translateText(type) {
      return {
        error: sprintf(s__('ciReport|Failed to load %{reportName} report'), {
          reportName: type,
        }),
        loading: sprintf(s__('ciReport|Loading %{reportName} report'), {
          reportName: type,
        }),
      };
    },
  },
};
</script>

<template>
  <div>
    <report-section
      always-open
      :status="codequalityStatus"
      :loading-text="translateText('codeclimate').loading"
      :error-text="translateText('codeclimate').error"
      :success-text="codequalityText"
      :unresolved-issues="codeQualityIssues"
      :resolved-issues="[]"
      :has-issues="hasCodequalityIssues"
      :component="$options.componentNames.CodequalityIssueBody"
      class="codequality-report"
    />
  </div>
</template>
