<script>
import dateFormat from 'dateformat';
import { GlDiscreteScatterChart } from '@gitlab/ui/dist/charts';
import { scatterChartLineProps, dateFormats } from '../constants';

export default {
  components: {
    GlDiscreteScatterChart,
  },
  props: {
    xAxisTitle: {
      type: String,
      required: true,
    },
    yAxisTitle: {
      type: String,
      required: true,
    },
    scatterData: {
      type: Array,
      required: true,
    },
    medianLineData: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      tooltipTitle: '',
      tooltipContent: '',
      chartOption: {
        xAxis: {
          type: 'time',
          axisLabel: {
            formatter: date => dateFormat(date, dateFormats.defaultDate),
          },
        },
        dataZoom: [
          {
            type: 'slider',
            bottom: 10,
            start: 0,
          },
        ],
      },
    };
  },
  computed: {
    chartData() {
      const result = [
        {
          type: 'scatter',
          data: this.scatterData,
        },
      ];

      if (this.medianLineData.length) {
        result.push({
          data: this.medianLineData,
          ...scatterChartLineProps.default,
        });
      }

      return result;
    },
  },
  methods: {
    renderTooltip({ data }) {
      const [, metric, dateTime] = data;
      this.tooltipTitle = metric;
      this.tooltipContent = dateFormat(dateTime, dateFormats.defaultDateTime);
    },
  },
};
</script>

<template>
  <gl-discrete-scatter-chart
    :data="chartData"
    :option="chartOption"
    :y-axis-title="yAxisTitle"
    :x-axis-title="xAxisTitle"
    :format-tooltip-text="renderTooltip"
  >
    <div slot="tooltipTitle">{{ tooltipTitle }}</div>
    <div slot="tooltipContent">{{ tooltipContent }}</div>
  </gl-discrete-scatter-chart>
</template>
