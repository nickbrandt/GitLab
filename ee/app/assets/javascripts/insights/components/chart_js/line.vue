<script>
import BaseChart from './insights_chart.vue';

export default {
  extends: BaseChart,
  computed: {
    config() {
      return {
        type: 'line',
        data: this.data,
        options: {
          ...this.title(),
          ...this.commonOptions(),
          ...this.elements(),
          ...this.scales(),
        },
      };
    },
  },
  methods: {
    elements() {
      return {
        elements: {
          line: {
            tension: 0,
            fill: false,
          },
        },
      };
    },
    scales() {
      return {
        scales: {
          yAxes: [
            {
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
    <canvas ref="insightsChart" class="line" height="300"></canvas>
  </div>
</template>
