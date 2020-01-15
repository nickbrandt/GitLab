<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import { componentNames } from 'ee/reports/components/issue_body';
import ReportSection from '~/reports/components/report_section.vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import { n__, s__, sprintf } from '~/locale';

import createStore from './store';

export default {
  store: createStore(),
  components: {
    ReportSection,
    PaginationLinks,
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
    ...mapState(['isLoadingCodequality', 'loadingCodequalityFailed', 'endpoint', 'pageInfo']),
    ...mapGetters(['codequalityIssues', 'codequalityIssueTotal']),
    hasCodequalityIssues() {
      return this.codequalityIssueTotal > 0;
    },
    codequalityText() {
      const text = [];
      const { codequalityIssueTotal } = this;

      if (codequalityIssueTotal === 0) {
        return s__('ciReport|No code quality issues found');
      } else if (codequalityIssueTotal > 0) {
        return sprintf(s__('ciReport|Found %{issuesWithCount}'), {
          issuesWithCount: n__(
            '%d code quality issue',
            '%d code quality issues',
            codequalityIssueTotal,
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
    ...mapActions(['setEndpoint', 'setBlobPath', 'setPage', 'fetchReport']),
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
      :unresolved-issues="codequalityIssues"
      :resolved-issues="[]"
      :has-issues="hasCodequalityIssues"
      :component="$options.componentNames.CodequalityIssueBody"
      class="codequality-report"
    />
    <pagination-links
      :change="setPage"
      :page-info="pageInfo"
      class="d-flex justify-content-center prepend-top-default"
    />
  </div>
</template>
