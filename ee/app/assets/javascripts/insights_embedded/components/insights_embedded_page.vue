<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';

import InsightsConfigWarning from '../../insights/components/insights_config_warning.vue';
import InsightsChart from '../../insights/components/insights_chart.vue';

export default {
  components: {
    GlLoadingIcon,
    InsightsChart,
    InsightsConfigWarning,
  },
  props: {
    queryEndpoint: {
      type: String,
      required: true,
    },
    specifiedChartIndex: {
      type: Number,
      default: null,
      required: false,
    },
    chartConfig: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState('insights', ['chartData', 'pageLoading']),
    chart() {
      return this.chartData[this.chartConfig.title];
    },
  },
  watch: {
    chartConfig() {
      this.setPageLoading(true);
      this.fetchChart();
    },
  },
  mounted() {
    this.fetchChart();
  },
  methods: {
    ...mapActions('insights', ['fetchChartData', 'initChartData', 'setPageLoading']),
    fetchChart() {
      this.initChartData([this.chartConfig.title]);

      this.fetchChartData({ endpoint: this.queryEndpoint, chart: this.chartConfig })
        .then(() => {
          this.setPageLoading(!this.chart);
        })
        .catch(() => {
          this.setPageLoading(false);
        });
    },
  },
};
</script>
<template>
  <div class="insights-page" data-qa-selector="insights_page">
    <div v-if="chart" class="js-insights-page-container">
      <div class="insights-charts">
        <insights-chart
          :loaded="chart.loaded"
          :type="chart.type"
          :title="chart.key"
          :description="chart.description"
          :data="chart.data"
          :error="chart.error"
        />
      </div>
      <div v-if="pageLoading" class="insights-chart-loading text-center p-5">
        <gl-loading-icon :inline="true" size="lg" />
      </div>
    </div>
    <insights-config-warning
      v-else
      :title="__('There are no charts configured for this page')"
      :summary="
        __(
          'Please check the configuration file to ensure that a collection of charts has been declared.',
        )
      "
      image="illustrations/monitoring/getting_started.svg"
    />
  </div>
</template>
