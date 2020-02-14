<script>
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';

const CHART_HEIGHT = 220;

export default {
  components: {
    GlColumnChart,
    ResizableChartContainer,
  },
  props: {
    chartData: {
      type: Array,
      required: true,
    },
    xAxisTitle: {
      type: String,
      required: false,
      default: '',
    },
    yAxisTitle: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      svgs: {},
    };
  },
  computed: {
    dataZoomConfig() {
      const handleIcon = this.svgs['scroll-handle'];

      return handleIcon ? { handleIcon } : {};
    },
    chartOptions() {
      return {
        dataZoom: [this.dataZoomConfig],
      };
    },
    seriesData() {
      return { full: this.chartData };
    },
  },
  methods: {
    setSvg(name) {
      return getSvgIconPathContent(name)
        .then(path => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch(e => {
          // eslint-disable-next-line no-console, @gitlab/i18n/no-non-i18n-strings
          console.error('SVG could not be rendered correctly: ', e);
        });
    },
    onChartCreated() {
      this.setSvg('scroll-handle');
    },
  },
  height: CHART_HEIGHT,
};
</script>

<template>
  <resizable-chart-container>
    <gl-column-chart
      slot-scope="{ width }"
      v-bind="$attrs"
      :width="width"
      :height="$options.height"
      :data="seriesData"
      :x-axis-title="xAxisTitle"
      :y-axis-title="yAxisTitle"
      x-axis-type="category"
      :option="chartOptions"
      @created="onChartCreated"
    />
  </resizable-chart-container>
</template>
