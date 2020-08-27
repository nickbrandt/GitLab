import { GlColumnChart, GlLineChart, GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';

import {
  chartInfo,
  barChartData,
  lineChartData,
  stackedBarChartData,
} from 'ee_jest/insights/mock_data';
import InsightsChart from 'ee/insights/components/insights_chart.vue';
import InsightsChartError from 'ee/insights/components/insights_chart_error.vue';
import { CHART_TYPES } from 'ee/insights/constants';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';

describe('Insights chart component', () => {
  let wrapper;

  const factory = propsData =>
    shallowMount(InsightsChart, {
      propsData,
      stubs: { 'gl-column-chart': true, 'insights-chart-error': true },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when chart is loading', () => {
    it('displays the chart loader', () => {
      wrapper = factory({
        loaded: false,
        type: CHART_TYPES.BAR,
        title: chartInfo.title,
        data: null,
        error: '',
      });

      expect(wrapper.find(ChartSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('when chart is loaded', () => {
    it('displays a bar chart', () => {
      wrapper = factory({
        loaded: true,
        type: CHART_TYPES.BAR,
        title: chartInfo.title,
        data: barChartData,
        error: '',
      });

      expect(wrapper.find(GlColumnChart).exists()).toBe(true);
    });

    it('displays a line chart', () => {
      wrapper = factory({
        loaded: true,
        type: CHART_TYPES.LINE,
        title: chartInfo.title,
        data: lineChartData,
        error: '',
      });

      expect(wrapper.find(GlLineChart).exists()).toBe(true);
    });

    it('displays a stacked bar chart', () => {
      wrapper = factory({
        loaded: true,
        type: CHART_TYPES.STACKED_BAR,
        title: chartInfo.title,
        data: stackedBarChartData,
        error: '',
      });

      expect(wrapper.find(GlStackedColumnChart).exists()).toBe(true);
    });

    it('displays a bar chart when a pie chart is requested', () => {
      wrapper = factory({
        loaded: true,
        type: CHART_TYPES.PIE,
        title: chartInfo.title,
        data: barChartData,
        error: '',
      });

      expect(wrapper.find(GlColumnChart).exists()).toBe(true);
    });
  });

  describe('when chart receives an error', () => {
    const error = 'my error';

    beforeEach(() => {
      wrapper = factory({
        loaded: false,
        type: chartInfo.type,
        title: chartInfo.title,
        data: {},
        error,
      });
    });

    it('displays info about the error', () => {
      expect(wrapper.find(InsightsChartError).exists()).toBe(true);
    });
  });
});
