<script>
import { mapGetters, mapActions, mapState } from 'vuex';
import { engineeringNotation, sum, average } from '@gitlab/ui/src/utils/number_utils';
import { GlLoadingIcon } from '@gitlab/ui';
import { GlColumnChart, GlChartLegend } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';
import { getMonthNames } from '~/lib/utils/datetime_utility';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import EmptyState from './empty_state.vue';

export default {
  components: {
    EmptyState,
    GlLoadingIcon,
    GlColumnChart,
    GlChartLegend,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    filterBlockEl: {
      type: HTMLDivElement,
      required: true,
    },
  },
  data() {
    return {
      svgs: {},
      chart: null,
      seriesInfo: [
        {
          type: 'solid',
          name: s__('IssuesAnalytics|Issues created'),
          color: '#1F78D1',
        },
      ],
    };
  },
  computed: {
    ...mapState('issueAnalytics', ['chartData', 'loading']),
    ...mapGetters('issueAnalytics', ['hasFilters', 'appliedFilters']),
    data() {
      const { chartData, chartHasData } = this;
      const data = [];

      if (chartHasData()) {
        Object.keys(chartData).forEach(key => {
          const date = new Date(key);
          const label = `${getMonthNames(true)[date.getUTCMonth()]} ${date.getUTCFullYear()}`;
          const val = chartData[key];

          data.push([label, val]);
        });
      }

      return data;
    },
    chartLabels() {
      return this.data.map(val => val[0]);
    },
    chartDateRange() {
      return `${this.chartLabels[0]} - ${this.chartLabels[this.chartLabels.length - 1]}`;
    },
    showChart() {
      return !this.loading && this.chartHasData();
    },
    showNoDataEmptyState() {
      return !this.loading && !this.showChart && !this.hasFilters;
    },
    showFiltersEmptyState() {
      return !this.loading && !this.showChart && this.hasFilters;
    },
    chartOptions() {
      return {
        dataZoom: [
          {
            type: 'slider',
            startValue: 0,
            handleIcon: this.svgs['scroll-handle'],
          },
        ],
      };
    },
    series() {
      return this.data.map(val => val[1]);
    },
    seriesAverage() {
      return engineeringNotation(average(...this.series), 0);
    },
    seriesTotal() {
      return engineeringNotation(sum(...this.series));
    },
  },
  watch: {
    appliedFilters() {
      this.fetchChartData(this.endpoint);
    },
    showNoDataEmptyState(showEmptyState) {
      if (showEmptyState) {
        this.$nextTick(() => this.filterBlockEl.classList.add('hide'));
      }
    },
  },
  created() {
    this.setSvg('scroll-handle');
  },
  mounted() {
    this.fetchChartData(this.endpoint);
  },
  methods: {
    ...mapActions('issueAnalytics', ['fetchChartData']),
    onCreated(chart) {
      this.chart = chart;
    },
    chartHasData() {
      if (!this.chartData) {
        return false;
      }

      return Object.values(this.chartData).some(val => val > 0);
    },
    setSvg(name) {
      getSvgIconPathContent(name)
        .then(path => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch(() => {});
    },
  },
};
</script>
<template>
  <div class="issues-analytics-wrapper" data-qa-selector="issues_analytics_wrapper">
    <div v-if="loading" class="issues-analytics-loading text-center">
      <gl-loading-icon :inline="true" :size="4" />
    </div>

    <div v-if="showChart" class="issues-analytics-chart">
      <h4 class="chart-title">{{ s__('IssuesAnalytics|Issues created per month') }}</h4>

      <gl-column-chart
        data-qa-selector="issues_analytics_graph"
        :data="{ Full: data }"
        :option="chartOptions"
        :y-axis-title="s__('IssuesAnalytics|Issues created')"
        :x-axis-title="s__('IssuesAnalytics|Last 12 months') + ' (' + chartDateRange + ')'"
        x-axis-type="category"
        @created="onCreated"
      />
      <div class="d-flex">
        <gl-chart-legend v-if="chart" :chart="chart" :series-info="seriesInfo" />
        <div class="issues-analytics-legend">
          <span>{{ s__('IssuesAnalytics|Total:') }} {{ seriesTotal }}</span>
          <span>&#8226;</span>
          <span>{{ s__('IssuesAnalytics|Avg/Month:') }} {{ seriesAverage }}</span>
        </div>
      </div>
    </div>

    <empty-state
      v-if="showFiltersEmptyState"
      image="illustrations/issues.svg"
      :title="s__('IssuesAnalytics|Sorry, your filter produced no results')"
      :summary="
        s__(
          'IssuesAnalytics|To widen your search, change or remove filters in the filter bar above',
        )
      "
    />

    <empty-state
      v-if="showNoDataEmptyState"
      image="illustrations/monitoring/getting_started.svg"
      :title="s__('IssuesAnalytics|There are no issues for the projects in your group')"
      :summary="
        s__(
          'IssuesAnalytics|After you begin creating issues for your projects, we can start tracking and displaying metrics for them',
        )
      "
    />
  </div>
</template>
