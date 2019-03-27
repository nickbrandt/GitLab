<script>
import BaseChart from './insights_chart.vue';
import * as chartOptions from '~/lib/utils/chart_utils';

export default {
  components: {
    BaseChart,
  },
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
        },
      };
    },
  },
};
</script>
<template>
  <div class="chart-canvas-wrapper">
    <canvas ref="insightsChart" class="bar" height="300"></canvas>
  </div>
</template>
