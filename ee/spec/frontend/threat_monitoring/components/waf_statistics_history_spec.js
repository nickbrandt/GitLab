import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import createStore from 'ee/threat_monitoring/store';
import WafStatisticsHistory from 'ee/threat_monitoring/components/waf_statistics_history.vue';
import { TOTAL_REQUESTS, ANOMALOUS_REQUESTS } from 'ee/threat_monitoring/components/constants';
import { mockWafStatisticsResponse } from '../mock_data';

let resizeCallback = null;
const MockResizeObserverDirective = {
  bind(el, { value }) {
    resizeCallback = value;
  },

  simulateResize() {
    // Let tests fail if callback throws or isn't callable
    resizeCallback();
  },

  unbind() {
    resizeCallback = null;
  },
};

const localVue = createLocalVue();
localVue.directive('gl-resize-observer-directive', MockResizeObserverDirective);

describe('WafStatisticsHistory component', () => {
  let store;
  let wrapper;

  const factory = ({ state, options } = {}) => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, state);

    wrapper = shallowMount(WafStatisticsHistory, {
      localVue,
      store,
      sync: false,
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findChart = () => wrapper.find(GlAreaChart);

  describe('the data passed to the chart', () => {
    beforeEach(() => {
      factory({
        state: {
          wafStatistics: {
            history: mockWafStatisticsResponse.history,
          },
        },
      });
    });

    it('is structured correctly', () => {
      const { nominal, anomalous } = mockWafStatisticsResponse.history;
      expect(findChart().props('data')).toMatchObject([{ data: anomalous }, { data: nominal }]);
    });
  });

  describe('given the component needs to resize', () => {
    let mockChartInstance;
    beforeEach(() => {
      factory();

      mockChartInstance = {
        resize: jest.fn(),
      };
    });

    describe('given the chart has not emitted the created event', () => {
      beforeEach(() => {
        MockResizeObserverDirective.simulateResize();
      });

      it('there is no attempt to resize the chart instance', () => {
        expect(mockChartInstance.resize).not.toHaveBeenCalled();
      });
    });

    describe('given the chart has emitted the created event', () => {
      beforeEach(() => {
        findChart().vm.$emit('created', mockChartInstance);
        MockResizeObserverDirective.simulateResize();
      });

      it('the chart instance is resized', () => {
        expect(mockChartInstance.resize).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('chart tooltip', () => {
    beforeEach(() => {
      const mockTotalSeriesDatum = mockWafStatisticsResponse.history.nominal[0];
      const mockAnomalousSeriesDatum = mockWafStatisticsResponse.history.anomalous[0];
      const mockParams = {
        seriesData: [
          {
            seriesName: ANOMALOUS_REQUESTS,
            value: mockAnomalousSeriesDatum,
          },
          {
            seriesName: TOTAL_REQUESTS,
            value: mockTotalSeriesDatum,
          },
        ],
      };

      factory({
        options: {
          stubs: {
            GlAreaChart: {
              props: ['formatTooltipText'],
              mounted() {
                this.formatTooltipText(mockParams);
              },
              template: `
                <div>
                  <slot name="tooltipTitle"></slot>
                  <slot name="tooltipContent"></slot>
                </div>`,
            },
          },
        },
      });

      return wrapper.vm.$nextTick();
    });

    it('renders the title and series data correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
