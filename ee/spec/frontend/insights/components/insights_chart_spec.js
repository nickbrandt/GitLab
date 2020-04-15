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

  describe('when chart is loaded', () => {
    it('displays a bar chart', () => {
      wrapper = factory({
        loaded: true,
        type: CHART_TYPES.BAR,
        title: chartInfo.title,
        data: barChartData,
        error: '',
      });

      expect(wrapper.contains(GlColumnChart)).toBe(true);
    });

    it('displays a line chart', () => {
      wrapper = factory({
        loaded: true,
        type: CHART_TYPES.LINE,
        title: chartInfo.title,
        data: lineChartData,
        error: '',
      });

      expect(wrapper.contains(GlLineChart)).toBe(true);
    });

    it('displays a stacked bar chart', () => {
      wrapper = factory({
        loaded: true,
        type: CHART_TYPES.STACKED_BAR,
        title: chartInfo.title,
        data: stackedBarChartData,
        error: '',
      });

      expect(wrapper.contains(GlStackedColumnChart)).toBe(true);
    });

    it('displays a bar chart when a pie chart is requested', () => {
      wrapper = factory({
        loaded: true,
        type: CHART_TYPES.PIE,
        title: chartInfo.title,
        data: barChartData,
        error: '',
      });

      expect(wrapper.contains(GlColumnChart)).toBe(true);
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
      expect(wrapper.contains(InsightsChartError)).toBe(true);
    });
  });
});
