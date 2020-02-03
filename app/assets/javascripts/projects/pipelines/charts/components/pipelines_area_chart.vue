<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { __ } from '~/locale';
import { CHART_CONTAINER_HEIGHT } from '../constants';

export default {
  components: {
    GlAreaChart,
  },
  props: {
    chartData: {
      type: Array,
      required: true,
    },
  },
  areaChartOptions: {
    xAxis: {
      name: __('Date'),
      type: 'category',
    },
    yAxis: {
      name: __('Pipelines'),
    },
  },
  chartContainerHeight: CHART_CONTAINER_HEIGHT,
};
</script>
<template>
  <div class="prepend-top-default">
    <p>
      <slot></slot>
    </p>
    <div>
      <gl-area-chart
        :height="$options.chartContainerHeight"
        :data="chartData"
        :include-legend-avg-max="false"
        :option="$options.areaChartOptions"
      />
    </div>
  </div>
</template>
