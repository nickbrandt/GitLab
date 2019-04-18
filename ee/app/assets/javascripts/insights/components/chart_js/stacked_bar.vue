<script>
import BaseChart from './insights_chart.vue';
import * as chartOptions from '~/lib/utils/chart_utils';

export default {
  extends: BaseChart,
  computed: {
    config() {
      return {
        type: 'bar',
        data: this.data,
        options: {
          ...chartOptions.barChartOptions(),
          ...this.title(),
          ...this.commonOptions(),
          ...this.tooltips(),
          ...this.scales(),
        },
      };
    },
  },
  methods: {
    tooltips() {
      return {
        tooltips: {
          mode: 'index',
        },
      };
    },
    scales() {
      return {
        scales: {
          xAxes: [
            {
              stacked: true,
            },
          ],
          yAxes: [
            {
              stacked: true,
              ticks: {
                beginAtZero: true,
              },
            },
          ],
        },
      };
    },
  },
};
</script>
<template>
  <div class="chart-canvas-wrapper">
    <canvas ref="insightsChart" class="stacked-bar" height="300"></canvas>
  </div>
</template>
