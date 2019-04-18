<script>
import BaseChart from './insights_chart.vue';
import * as chartOptions from '~/lib/utils/chart_utils';

export default {
  extends: BaseChart,
  computed: {
    config() {
      return {
        type: 'pie',
        data: this.data,
        options: {
          ...chartOptions.pieChartOptions(),
          ...this.title(),
          ...this.commonOptions(),
        },
      };
    },
  },
};
</script>
<template>
  <div class="chart-canvas-wrapper">
    <canvas ref="insightsChart" class="pie" height="180"></canvas>
  </div>
</template>
