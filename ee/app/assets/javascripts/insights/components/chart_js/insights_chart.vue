<script>
import Chart from 'chart.js';

export default {
  props: {
    chartTitle: {
      type: String,
      required: true,
    },
    data: {
      type: Object,
      required: true,
    },
  },
  computed: {
    config() {
      return {};
    },
  },
  mounted() {
    this.drawChart();
  },
  methods: {
    title() {
      return {
        title: {
          display: true,
          text: this.chartTitle,
        },
      };
    },
    commonOptions() {
      return {
        responsive: true,
        maintainAspectRatio: false,
        legend: false,
      };
    },
    drawChart() {
      const ctx = this.$refs.insightsChart.getContext('2d');
      return new Chart(ctx, this.config);
    },
  },
};
</script>
<template>
  <div class="chart-canvas-wrapper">
    <canvas ref="insightsChart" height="300"></canvas>
  </div>
</template>
