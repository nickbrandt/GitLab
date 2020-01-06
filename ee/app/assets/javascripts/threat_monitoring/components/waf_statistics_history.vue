<script>
import _ from 'underscore';
import dateFormat from 'dateformat';
import { mapState } from 'vuex';
import { GlResizeObserverDirective } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';

import {
  ANOMALOUS_REQUESTS,
  COLORS,
  DATE_FORMATS,
  REQUESTS,
  TIME,
  TOTAL_REQUESTS,
} from './constants';

export default {
  name: 'WafStatisticsHistoryChart',
  components: {
    GlAreaChart,
  },
  directives: {
    GlResizeObserverDirective,
  },
  data() {
    return {
      chartInstance: null,
      tooltipSeriesData: null,
      tooltipTitle: '',
    };
  },
  computed: {
    ...mapState('threatMonitoring', ['wafStatistics']),
    chartData() {
      const { anomalous, nominal } = this.wafStatistics.history;
      const anomalousStyle = { color: COLORS.anomalous };
      const nominalStyle = { color: COLORS.nominal };

      return [
        {
          name: ANOMALOUS_REQUESTS,
          data: anomalous,
          areaStyle: anomalousStyle,
          lineStyle: anomalousStyle,
          itemStyle: anomalousStyle,
        },
        {
          name: TOTAL_REQUESTS,
          data: nominal,
          areaStyle: nominalStyle,
          lineStyle: nominalStyle,
          itemStyle: nominalStyle,
        },
      ];
    },
  },
  chartOptions: {
    xAxis: {
      name: TIME,
      type: 'time',
      axisLabel: {
        formatter: value => dateFormat(value, DATE_FORMATS.defaultDate),
      },
    },
    yAxis: {
      name: REQUESTS,
    },
  },
  methods: {
    formatTooltipText({ seriesData }) {
      this.tooltipSeriesData = seriesData;
      const [timestamp] = seriesData[0].value;
      this.tooltipTitle = dateFormat(timestamp, DATE_FORMATS.defaultDateTime);
    },
    onChartCreated(chartInstance) {
      this.chartInstance = chartInstance;
    },
    onResize() {
      if (_.isFunction(this.chartInstance?.resize)) {
        this.chartInstance.resize();
      }
    },
  },
};
</script>

<template>
  <gl-area-chart
    v-gl-resize-observer-directive="onResize"
    :data="chartData"
    :option="$options.chartOptions"
    :include-legend-avg-max="false"
    :format-tooltip-text="formatTooltipText"
    @created="onChartCreated"
  >
    <template #tooltipTitle>
      <div>{{ tooltipTitle }} ({{ $options.chartOptions.xAxis.name }})</div>
    </template>

    <template #tooltipContent>
      <div v-for="series in tooltipSeriesData" :key="series.seriesName" class="d-flex">
        <div class="flex-grow-1 mr-5">{{ series.seriesName }}</div>
        <div class="font-weight-bold">{{ series.value[1] }}</div>
      </div>
    </template>
  </gl-area-chart>
</template>
