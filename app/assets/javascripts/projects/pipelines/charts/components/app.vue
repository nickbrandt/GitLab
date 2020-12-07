<script>
import dateFormat from 'dateformat';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { __, s__, sprintf } from '~/locale';
import createFlash, { FLASH_TYPES } from '~/flash';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import getPipelineCountByStatus from '../graphql/queries/get_pipeline_count_by_status.query.graphql';
import getProjectPipelineStatistics from '../graphql/queries/get_project_pipeline_statistics.query.graphql';
import StatisticsList from './statistics_list.vue';
import PipelinesAreaChart from './pipelines_area_chart.vue';
import {
  CHART_CONTAINER_HEIGHT,
  CHART_DATE_FORMAT,
  INNER_CHART_HEIGHT,
  ONE_WEEK_AGO_DAYS,
  ONE_MONTH_AGO_DAYS,
  X_AXIS_LABEL_ROTATION,
  X_AXIS_TITLE_OFFSET,
} from '../constants';

const defaultCountValues = {
  totalPipelines: {
    count: 0,
  },
  successfulPipelines: {
    count: 0,
  },
};

const defaultAnalyticsValues = {
  weekPipelinesTotals: [],
  weekPipelinesLabels: [],
  weekPipelinesSuccessful: [],
  monthPipelinesLabels: [],
  monthPipelinesTotals: [],
  monthPipelinesSuccessful: [],
  yearPipelinesLabels: [],
  yearPipelinesTotals: [],
  yearPipelinesSuccessful: [],
  pipelineTimesLabels: [],
  pipelineTimesValues: [],
};

export default {
  components: {
    GlColumnChart,
    StatisticsList,
    PipelinesAreaChart,
  },
  inject: {
    projectPath: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      counts: {
        ...defaultCountValues,
      },
      analytics: {
        ...defaultAnalyticsValues,
      },
    };
  },
  apollo: {
    counts: {
      query: getPipelineCountByStatus,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(res) {
        return res.project;
      },
      error() {
        createFlash({
          message: s__('PipelineCharts|An error has ocurred when retrieving the pipeline data'),
          type: FLASH_TYPES.ALERT,
        });
      },
    },
    analytics: {
      query: getProjectPipelineStatistics,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(res) {
        return res.project.pipelineAnalytics;
      },
      error() {
        createFlash({
          message: s__('PipelineCharts|An error has ocurred when retrieving the analytics data'),
          type: FLASH_TYPES.ALERT,
        });
      },
    },
  },
  computed: {
    successRatio() {
      const { successfulPipelines, failedPipelines } = this.counts;
      const successfulCount = successfulPipelines?.count;
      const failedCount = failedPipelines?.count;
      const ratio = (successfulCount / (successfulCount + failedCount)) * 100;

      return failedCount === 0 ? 100 : ratio;
    },
    formattedCounts() {
      const {
        totalPipelines,
        successfulPipelines,
        failedPipelines,
        totalPipelineDuration,
      } = this.counts;

      return {
        total: totalPipelines?.count,
        success: successfulPipelines?.count,
        failed: failedPipelines?.count,
        successRatio: this.successRatio,
        totalDuration: totalPipelineDuration,
      };
    },
    areaCharts() {
      const { lastWeek, lastMonth, lastYear } = this.$options.chartTitles;

      return [
        this.buildAreaChartData(lastWeek, this.lastWeekChartData),
        this.buildAreaChartData(lastMonth, this.lastMonthChartData),
        this.buildAreaChartData(lastYear, this.lastYearChartData),
      ];
    },
    lastWeekChartData() {
      return {
        labels: this.analytics.weekPipelinesLabels,
        totals: this.analytics.weekPipelinesTotals,
        success: this.analytics.weekPipelinesSuccessful,
      };
    },
    lastMonthChartData() {
      return {
        labels: this.analytics.monthPipelinesLabels,
        totals: this.analytics.monthPipelinesTotals,
        success: this.analytics.monthPipelinesSuccessful,
      };
    },
    lastYearChartData() {
      return {
        labels: this.analytics.yearPipelinesLabels,
        totals: this.analytics.yearPipelinesTotals,
        success: this.analytics.yearPipelinesSuccessful,
      };
    },
    timesChartTransformedData() {
      return [
        {
          name: 'full',
          data: this.mergeLabelsAndValues(
            this.analytics.pipelineTimesLabels,
            this.analytics.pipelineTimesValues,
          ),
        },
      ];
    },
  },
  methods: {
    mergeLabelsAndValues(labels, values) {
      return labels.map((label, index) => [label, values[index]]);
    },
    buildAreaChartData(title, data) {
      const { labels, totals, success } = data;

      return {
        title,
        data: [
          {
            name: 'all',
            data: this.mergeLabelsAndValues(labels, totals),
          },
          {
            name: 'success',
            data: this.mergeLabelsAndValues(labels, success),
          },
        ],
      };
    },
  },
  chartContainerHeight: CHART_CONTAINER_HEIGHT,
  timesChartOptions: {
    height: INNER_CHART_HEIGHT,
    xAxis: {
      axisLabel: {
        rotate: X_AXIS_LABEL_ROTATION,
      },
      nameGap: X_AXIS_TITLE_OFFSET,
    },
  },
  get chartTitles() {
    const today = dateFormat(new Date(), CHART_DATE_FORMAT);
    const pastDate = timeScale =>
      dateFormat(getDateInPast(new Date(), timeScale), CHART_DATE_FORMAT);
    return {
      lastWeek: sprintf(__('Pipelines for last week (%{oneWeekAgo} - %{today})'), {
        oneWeekAgo: pastDate(ONE_WEEK_AGO_DAYS),
        today,
      }),
      lastMonth: sprintf(__('Pipelines for last month (%{oneMonthAgo} - %{today})'), {
        oneMonthAgo: pastDate(ONE_MONTH_AGO_DAYS),
        today,
      }),
      lastYear: __('Pipelines for last year'),
    };
  },
};
</script>
<template>
  <div>
    <div class="gl-mb-3">
      <h3>{{ s__('PipelineCharts|CI / CD Analytics') }}</h3>
    </div>
    <h4 class="gl-my-4">{{ s__('PipelineCharts|Overall statistics') }}</h4>
    <div class="row">
      <div class="col-md-6">
        <statistics-list :counts="formattedCounts" />
      </div>
      <div class="col-md-6">
        <strong>
          {{ __('Duration for the last 30 commits') }}
        </strong>
        <gl-column-chart
          :height="$options.chartContainerHeight"
          :option="$options.timesChartOptions"
          :bars="timesChartTransformedData"
          :y-axis-title="__('Minutes')"
          :x-axis-title="__('Commit')"
          x-axis-type="category"
        />
      </div>
    </div>
    <hr />
    <h4 class="gl-my-4">{{ __('Pipelines charts') }}</h4>
    <pipelines-area-chart
      v-for="(chart, index) in areaCharts"
      :key="index"
      :chart-data="chart.data"
    >
      {{ chart.title }}
    </pipelines-area-chart>
  </div>
</template>
