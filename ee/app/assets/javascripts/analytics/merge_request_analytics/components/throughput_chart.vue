<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ThroughputChart',
  components: {
    GlAreaChart,
    GlAlert,
  },
  data() {
    return {
      throughputChartData: [],
    };
  },
  computed: {
    chartOptions() {
      return {
        xAxis: {
          name: '',
        },
        yAxis: {
          name: __('Merge Requests closed'),
        },
      };
    },
    chartDataAvailable() {
      return this.throughputChartData.length;
    },
  },
  chartTitle: __('Throughput'),
  chartDescription: __('The number of merge requests merged to the master branch by month.'),
};
</script>
<template>
  <div>
    <h4 data-testid="chartTitle">{{ $options.chartTitle }}</h4>
    <div class="gl-text-gray-700" data-testid="chartDescription">
      {{ $options.chartDescription }}
    </div>
    <gl-area-chart v-if="chartDataAvailable" :data="throughputChartData" :option="chartOptions" />
    <gl-alert v-else :dismissible="false" class="gl-mt-4">{{
      __('There is no data available.')
    }}</gl-alert>
  </div>
</template>
