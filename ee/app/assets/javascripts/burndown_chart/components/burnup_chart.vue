<script>
import { GlLineChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlLineChart,
    ResizableChartContainer,
  },
  props: {
    startDate: {
      type: String,
      required: true,
    },
    dueDate: {
      type: String,
      required: true,
    },
    scope: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      tooltip: {
        title: '',
        content: '',
      },
    };
  },
  computed: {
    dataSeries() {
      const series = [
        {
          name: __('Total'),
          data: this.scope,
        },
      ];

      return series;
    },
    options() {
      return {
        xAxis: {
          name: '',
          type: 'time',
          min: this.startDate,
          max: this.dueDate,
          axisLine: {
            show: true,
          },
        },
        yAxis: {
          name: __('Total issues'),
          axisLine: {
            show: true,
          },
          splitLine: {
            show: false,
          },
        },
        tooltip: {
          trigger: 'item',
          formatter: () => '',
        },
      };
    },
  },
  methods: {
    formatTooltipText(params) {
      const [seriesData] = params.seriesData;
      this.tooltip.title = dateFormat(params.value, 'dd mmm yyyy');

      const text = __('%{total} open issues');

      this.tooltip.content = sprintf(text, {
        total: seriesData.value[1],
      });
    },
  },
};
</script>

<template>
  <div data-qa-selector="burnup_chart">
    <div class="burndown-header d-flex align-items-center">
      <h3>{{ __('Burnup chart') }}</h3>
    </div>
    <resizable-chart-container class="js-burnup-chart">
      <gl-line-chart :data="dataSeries" :option="options" :format-tooltip-text="formatTooltipText">
        <template slot="tooltipTitle">{{ tooltip.title }}</template>
        <template slot="tooltipContent">{{ tooltip.content }}</template>
      </gl-line-chart>
    </resizable-chart-container>
  </div>
</template>
