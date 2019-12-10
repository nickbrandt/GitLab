<script>
import axios from 'axios';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import { componentNames } from 'ee/reports/components/issue_body';
import ReportSection from '~/reports/components/report_section.vue';
import CodequalityIssueBody from 'ee/vue_merge_request_widget/components/codequality_issue_body.vue';
import { n__, s__, sprintf } from '~/locale';

import MergeRequestStore from 'ee/vue_merge_request_widget/stores/mr_widget_store';

export default {
  name: 'CodequalityReport',
  components: {
    ReportSection,
    CodequalityIssueBody,
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
  data() {
    return {
      issues: [],
    };
  },
  computed: {
    hasCodequalityIssues() {
      return this.issues.length > 0;
    },
    codequalityText() {
      const text = [];
      const { issues } = this;

      if (!issues.length) {
        return s__('ciReport|No code quality issues found');
      } else if (issues.length) {
        return sprintf(s__('ciReport|Found %{issuesWithCount}'), {
          issuesWithCount: n__('%d code quality issue', '%d code quality issues', issues.length),
        });
      }

      return text.join('');
    },
    codequalityStatus() {
      return this.checkReportStatus(this.isLoadingCodequality, this.loadingCodequalityFailed);
    },
  },
  created() {
    return axios.get(this.codequalityReportDownloadPath).then(res => {
      this.issues = MergeRequestStore.parseCodeclimateMetrics(res.data, this.blobPath);
    });
  },
  methods: {
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
      :unresolved-issues="issues"
      :resolved-issues="[]"
      :has-issues="true"
      :component="$options.componentNames.CodequalityIssueBody"
      class="codequality-report"
    />
  </div>
</template>
