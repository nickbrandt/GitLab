<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { componentNames } from '~/reports/components/issue_body';
import ReportSection from '~/reports/components/report_section.vue';
import createStore from './store';

export default {
  name: 'GroupedCodequalityReportsApp',
  store: createStore(),
  components: {
    ReportSection,
  },
  props: {
    headPath: {
      type: String,
      required: true,
    },
    headBlobPath: {
      type: String,
      required: true,
    },
    basePath: {
      type: String,
      required: false,
      default: null,
    },
    baseBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    codequalityHelpPath: {
      type: String,
      required: true,
    },
  },
  componentNames,
  computed: {
    ...mapState(['newIssues', 'resolvedIssues']),
    ...mapGetters([
      'hasCodequalityIssues',
      'codequalityStatus',
      'codequalityText',
      'codequalityPopover',
    ]),
  },
  created() {
    this.setPaths({
      basePath: this.basePath,
      headPath: this.headPath,
      baseBlobPath: this.baseBlobPath,
      headBlobPath: this.headBlobPath,
      helpPath: this.codequalityHelpPath,
    });

    this.fetchReports();
  },
  methods: {
    ...mapActions(['fetchReports', 'setPaths']),
  },
};
</script>
<template>
  <report-section
    :status="codequalityStatus"
    :loading-text="
      sprintf(s__('ciReport|Loading %{reportName} report'), {
        reportName: 'codeclimate',
      })
    "
    :error-text="
      sprintf(s__('ciReport|Failed to load %{reportName} report'), {
        reportName: 'codeclimate',
      })
    "
    :success-text="codequalityText"
    :unresolved-issues="newIssues"
    :resolved-issues="resolvedIssues"
    :has-issues="hasCodequalityIssues"
    :component="$options.componentNames.CodequalityIssueBody"
    :popover-options="codequalityPopover"
    class="js-codequality-widget mr-widget-border-top mr-report"
  />
</template>
