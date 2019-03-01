<script>
import { mapActions, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import StackedBar from './chart_js/stacked_bar.vue';
import Bar from './chart_js/bar.vue';
import LineChart from './chart_js/line.vue';

export default {
  components: {
    GlLoadingIcon,
    NavigationTabs,
    StackedBar,
    Bar,
    LineChart,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    queryEndpoint: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('insights', [
      'configData',
      'configLoading',
      'activeTab',
      'activeChart',
      'chartData',
      'chartLoading',
    ]),
    navigationTabs() {
      const { configData, activeTab } = this;

      if (!configData) {
        return [];
      }

      if (!activeTab) {
        this.setActiveTab(Object.keys(configData)[0]);
      }

      return Object.keys(configData).map(key => ({
        name: configData[key].title,
        scope: key,
        isActive: this.activeTab === key,
      }));
    },
    chartType() {
      switch (this.activeChart.type) {
        case 'line':
          // Apparently Line clashes with another component
          return 'line-chart';
        default:
          return this.activeChart.type;
      }
    },
    drawChart() {
      return this.chartData && this.activeChart && !this.chartLoading;
    },
  },
  watch: {
    activeChart() {
      this.fetchChartData(this.queryEndpoint);
    },
  },
  mounted() {
    this.fetchConfigData(this.endpoint);
  },
  methods: {
    ...mapActions('insights', ['fetchConfigData', 'fetchChartData', 'setActiveTab']),
    onChangeTab(scope) {
      this.setActiveTab(scope);
    },
  },
};
</script>
<template>
  <div class="insights-container">
    <div v-if="configLoading" class="insights-config-loading text-center">
      <gl-loading-icon :inline="true" :size="4" />
    </div>
    <div v-else class="insights-wrapper">
      <div class="top-area scrolling-tabs-container inner-page-scroll-tabs">
        <navigation-tabs :tabs="navigationTabs" @onChangeTab="onChangeTab" />
      </div>
      <div class="insights-chart">
        <div v-if="chartLoading" class="insights-chart-loading text-center">
          <gl-loading-icon :inline="true" :size="4" />
        </div>
        <component :is="chartType" v-if="drawChart" :info="activeChart" :data="chartData" />
      </div>
    </div>
  </div>
</template>
