<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { pikadayToString } from '~/lib/utils/datetime_utility';

export default {
  name: 'GroupRepositoryAnalytics',
  components: {
    GlButton,
  },
  inject: {
    groupAnalyticsCoverageReportsPath: {
      type: String,
      default: '',
    },
  },
  computed: {
    csvReportPath() {
      const today = new Date();
      const endDate = pikadayToString(today);
      today.setFullYear(today.getFullYear() - 1);
      const startDate = pikadayToString(today);
      return `${this.groupAnalyticsCoverageReportsPath}&start_date=${startDate}&end_date=${endDate}`;
    },
  },
  text: {
    codeCoverageHeader: __('RepositoriesAnalytics|Test Code Coverage'),
    downloadCSVButton: __('RepositoriesAnalytics|Download historic test coverage data (.csv)'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
    <h4 class="sub-header">{{ $options.text.codeCoverageHeader }}</h4>
    <gl-button
      :href="csvReportPath"
      rel="nofollow"
      download
      data-testid="group-code-coverage-csv-button"
      >{{ $options.text.downloadCSVButton }}</gl-button
    >
  </div>
</template>
