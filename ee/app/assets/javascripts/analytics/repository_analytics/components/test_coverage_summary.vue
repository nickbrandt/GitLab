<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { GlCard, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import MetricCard from '~/analytics/shared/components/metric_card.vue';
import { formatDate } from '~/lib/utils/datetime_utility';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import getGroupTestCoverage from '../graphql/queries/get_group_test_coverage.query.graphql';

const formatPercent = getFormatter(SUPPORTED_FORMATS.percentHundred);

export default {
  name: 'TestCoverageSummary',
  components: {
    ChartSkeletonLoader,
    GlAreaChart,
    GlCard,
    GlSprintf,
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
        const THIRTY_DAYS = 30 * 24 * 60 * 60 * 1000; // milliseconds

        return {
          groupFullPath: this.groupFullPath,
          startDate: formatDate(new Date(Date.now() - THIRTY_DAYS), 'yyyy-mm-dd'),
        };
      },
      result({ data }) {
        const groupCoverage = data.group.codeCoverageActivities.nodes;
        const { projectCount, averageCoverage, coverageCount } =
          groupCoverage?.[groupCoverage.length - 1] || {};

        this.projectCount = projectCount;
        this.averageCoverage = averageCoverage;
        this.coverageCount = coverageCount;
        this.groupCoverageChartData = [
          {
            name: this.$options.i18n.graphName,
            data: groupCoverage.map((coverage) => [coverage.date, coverage.averageCoverage]),
          },
        ];
      },
      error() {
        this.hasError = true;
        this.projectCount = null;
        this.averageCoverage = null;
        this.coverageCount = null;
        this.groupCoverageChartData = [];
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
      groupCoverageChartData: [],
      coveragePercentage: null,
      tooltipTitle: null,
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
          label: this.$options.i18n.metrics.projectCountLabel,
        },
        {
          key: 'averageCoverage',
          value: this.averageCoverage,
          unit: '%',
          label: this.$options.i18n.metrics.averageCoverageLabel,
        },
        {
          key: 'coverageCount',
          value: this.coverageCount,
          label: this.$options.i18n.metrics.coverageCountLabel,
        },
      ];
    },
    chartOptions() {
      return {
        xAxis: {
          name: this.$options.i18n.xAxisName,
          type: 'time',
          axisLabel: {
            formatter: (value) => formatDate(value, 'mmm dd'),
          },
        },
        yAxis: {
          name: this.$options.i18n.yAxisName,
          type: 'value',
          min: 0,
          max: 100,
          axisLabel: {
            /**
             * We can't do `formatter: formatPercent` because
             * formatter passes in a second argument of index, which
             * formatPercent takes in as the number of decimal points
             * we should include after. This formats 100 as 100.00000%
             * instead of 100%.
             */
            formatter: (value) => formatPercent(value),
          },
        },
      };
    },
  },
  methods: {
    formatTooltipText(params) {
      this.tooltipTitle = formatDate(params.value, 'mmm dd');
      this.coveragePercentage = formatPercent(params.seriesData?.[0]?.data?.[1], 2);
    },
  },
  i18n: {
    graphCardHeader: s__('RepositoriesAnalytics|Average test coverage last 30 days'),
    yAxisName: __('Coverage'),
    xAxisName: __('Date'),
    graphName: s__('RepositoriesAnalytics|Average coverage'),
    graphTooltipMessage: __('Code Coverage: %{coveragePercentage}'),
    metrics: {
      cardTitle: __('Overall activity'),
      projectCountLabel: s__('RepositoriesAnalytics|Projects with Coverage'),
      averageCoverageLabel: s__('RepositoriesAnalytics|Average Coverage by Job'),
      coverageCountLabel: s__('RepositoriesAnalytics|Jobs with Coverage'),
    },
  },
};
</script>
<template>
  <div>
    <metric-card
      :title="$options.i18n.metrics.cardTitle"
      :metrics="metrics"
      :is-loading="isLoading"
    />

    <gl-card>
      <template #header>
        <h5>{{ $options.i18n.graphCardHeader }}</h5>
      </template>

      <chart-skeleton-loader v-if="isLoading" data-testid="group-coverage-chart-loading" />

      <gl-area-chart
        v-else
        :data="groupCoverageChartData"
        :option="chartOptions"
        :include-legend-avg-max="false"
        :format-tooltip-text="formatTooltipText"
        data-testid="group-coverage-chart"
      >
        <template #tooltip-title>
          {{ tooltipTitle }}
        </template>
        <template #tooltip-content>
          <gl-sprintf :message="$options.i18n.graphTooltipMessage">
            <template #coveragePercentage>
              {{ coveragePercentage }}
            </template>
          </gl-sprintf>
        </template>
      </gl-area-chart>
    </gl-card>
  </div>
</template>
