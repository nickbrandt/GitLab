<script>
import { s__ } from '~/locale';
import MetricCard from '~/analytics/shared/components/metric_card.vue';
import getGroupTestCoverage from '../graphql/queries/get_group_test_coverage.query.graphql';

export default {
  name: 'TestCoverageSummary',
  components: {
    MetricCard,
  },
  inject: {
    groupFullPath: {
      default: '',
    },
  },
  apollo: {
    group: {
      query: getGroupTestCoverage,
      variables() {
        return {
          groupFullPath: this.groupFullPath,
          startDate: new Date(Date.now() - 604800000), // one week ago
        };
      },
      result(res) {
        const { projectCount, averageCoverage, coverageCount } =
          res.data?.group?.codeCoverageActivities?.nodes?.[0] || {};

        this.projectCount = projectCount;
        this.averageCoverage = averageCoverage;
        this.coverageCount = coverageCount;
      },
      error() {
        this.hasError = true;
        this.projectCount = null;
        this.averageCoverage = null;
        this.coverageCount = null;
      },
      watchLoading(isLoading) {
        this.isLoading = isLoading;
      },
    },
  },
  data() {
    return {
      projectCount: null,
      averageCoverage: null,
      coverageCount: null,
      hasError: false,
      isLoading: false,
    };
  },
  computed: {
    metrics() {
      return [
        {
          key: 'projectCount',
          value: this.projectCount,
          label: s__('RepositoriesAnalytics|Projects with Tests'),
        },
        {
          key: 'averageCoverage',
          value: this.averageCoverage,
          unit: '%',
          label: s__('RepositoriesAnalytics|Average Coverage by Job'),
        },
        {
          key: 'coverageCount',
          value: this.coverageCount,
          label: s__('RepositoriesAnalytics|Total Number of Coverages'),
        },
      ];
    },
  },
};
</script>
<template>
  <metric-card :title="__('Overall Activity')" :metrics="metrics" :is-loading="isLoading" />
</template>
