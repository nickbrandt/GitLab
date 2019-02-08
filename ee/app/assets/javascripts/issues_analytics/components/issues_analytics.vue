<script>
import { mapGetters, mapActions, mapState } from 'vuex';
import Chart from 'chart.js';
import { GlLoadingIcon } from '@gitlab/ui';
import bp from '~/breakpoints';
import { getMonthNames } from '~/lib/utils/datetime_utility';
import EmptyState from './empty_state.vue';
import { CHART_OPTNS, CHART_COLORS } from '../constants';

export default {
  components: {
    EmptyState,
    GlLoadingIcon,
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
      drawChart: true,
      chartOptions: {
        ...CHART_OPTNS,
      },
      showPopover: false,
      popoverTitle: '',
      popoverContent: '',
      popoverPositionLeft: true,
    };
  },
  computed: {
    ...mapState('issueAnalytics', ['chartData', 'loading']),
    ...mapGetters('issueAnalytics', ['hasFilters', 'appliedFilters']),
    chartLabels() {
      const { chartData, chartHasData } = this;
      const labels = [];

      if (chartHasData()) {
        Object.keys(chartData).forEach(label => {
          const date = new Date(label);
          labels.push(`${getMonthNames(true)[date.getUTCMonth()]} ${date.getUTCFullYear()}`);
        });
      }

      return labels;
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
  },
  watch: {
    chartData() {
      // If chart data changes we need to redraw chart
      if (this.chartHasData()) {
        this.drawChart = true;
      }
    },
    appliedFilters() {
      this.fetchChartData(this.endpoint);
    },
    showNoDataEmptyState(showEmptyState) {
      if (showEmptyState) {
        this.$nextTick(() => this.filterBlockEl.classList.add('hide'));
      }
    },
  },
  mounted() {
    this.fetchChartData(this.endpoint);
  },
  updated() {
    // Only render chart when DOM is ready
    if (this.showChart && this.drawChart) {
      this.$nextTick(() => {
        this.createChart();
      });
    }
  },
  methods: {
    ...mapActions('issueAnalytics', ['fetchChartData']),
    createChart() {
      const { chartData, chartOptions, chartLabels } = this;
      const largeBreakpoints = ['md', 'lg'];

      // Reset spacing of chart item on large screens
      if (largeBreakpoints.includes(bp.getBreakpointSize())) {
        chartOptions.barValueSpacing = 12;
      }

      // Render chart when DOM has been updated
      this.$nextTick(() => {
        const ctx = this.$refs.issuesChart.getContext('2d');

        this.drawChart = false;
        return new Chart(ctx, {
          type: 'bar',
          data: {
            labels: chartLabels,
            datasets: [
              {
                ...CHART_COLORS,
                data: Object.values(chartData),
              },
            ],
          },
          options: {
            ...chartOptions,
            tooltips: {
              enabled: false,
              custom: tooltip => this.generateCustomTooltip(tooltip, ctx.canvas),
            },
          },
        });
      });
    },
    generateCustomTooltip(tooltip, canvas) {
      if (!tooltip.opacity) {
        this.showPopover = false;
        return;
      }

      // Find Y Location on page
      let top; // Find Y Location on page
      if (tooltip.yAlign === 'above') {
        top = tooltip.y - tooltip.caretSize - tooltip.caretPadding;
      } else {
        top = tooltip.y + tooltip.caretSize + tooltip.caretPadding;
      }

      [this.popoverTitle] = tooltip.title;
      [this.popoverContent] = tooltip.body[0].lines;
      this.showPopover = true;

      this.$nextTick(() => {
        const tooltipEl = this.$refs.chartTooltip;
        const tooltipWidth = tooltipEl.getBoundingClientRect().width;
        const tooltipLeftOffest = window.innerWidth - tooltipWidth;
        const tooltipLeftPosition = canvas.offsetLeft + tooltip.caretX;

        this.popoverPositionLeft = tooltipLeftPosition < tooltipLeftOffest;
        tooltipEl.style.top = `${canvas.offsetTop + top}px`;

        // Move tooltip to the right if too close to the left
        if (this.popoverPositionLeft) {
          tooltipEl.style.left = `${tooltipLeftPosition}px`;
        } else {
          tooltipEl.style.left = `${tooltipLeftPosition - tooltipWidth}px`;
        }
      });
    },
    chartHasData() {
      if (!this.chartData) {
        return false;
      }

      return Object.values(this.chartData).reduce((acc, value) => acc + parseInt(value, 10), 0) > 0;
    },
  },
};
</script>
<template>
  <div class="issues-analytics-wrapper">
    <div v-if="loading" class="issues-analytics-loading text-center">
      <gl-loading-icon :inline="true" :size="4" />
    </div>
    <div v-if="showChart" class="issues-analytics-chart">
      <h4 class="chart-title">{{ s__('IssuesAnalytics|Issues created per month') }}</h4>
      <div class="d-flex">
        <div class="chart-legend d-none d-sm-block bold align-self-center">
          {{ s__('IssuesAnalytics|Issues Created') }}
        </div>
        <div class="chart-canvas-wrapper">
          <canvas ref="issuesChart" height="300" class="append-bottom-15"></canvas>
        </div>
      </div>
      <p class="bold text-center">
        {{ s__('IssuesAnalytics|Last 12 months') }} ({{ chartDateRange }})
      </p>
      <div
        ref="chartTooltip"
        :class="[
          showPopover ? 'show' : 'hide',
          popoverPositionLeft ? 'bs-popover-right' : 'bs-popover-left',
        ]"
        class="popover no-pointer-events"
        role="tooltip"
      >
        <div class="arrow"></div>
        <h3 class="popover-header">{{ popoverTitle }}</h3>
        <div class="popover-body">
          <span class="popover-label">{{ s__('IssuesAnalytics|Issues Created') }}</span>
          {{ popoverContent }}
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
