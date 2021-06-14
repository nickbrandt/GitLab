import { createLocalVue, shallowMount } from '@vue/test-utils';
import { TOTAL_REQUESTS, ANOMALOUS_REQUESTS } from 'ee/threat_monitoring/components/constants';
import StatisticsHistory from 'ee/threat_monitoring/components/statistics_history.vue';
import { mockNominalHistory, mockAnomalousHistory } from '../mocks/mock_data';

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

describe('StatisticsHistory component', () => {
  let wrapper;
  const mockChartInstance = {
    resize: jest.fn(),
  };

  const factory = ({ options } = {}) => {
    wrapper = shallowMount(StatisticsHistory, {
      localVue,
      propsData: {
        data: {
          anomalous: { title: 'Anomoulous', values: mockAnomalousHistory },
          nominal: { title: 'Total', values: mockNominalHistory },
          from: 'foo',
          to: 'bar',
        },
        yLegend: 'Requests',
      },
      stubs: { GlAreaChart: true },
      data: () => {
        return { chartInstance: mockChartInstance };
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findChart = () => wrapper.find('glareachart-stub');

  describe('the data passed to the chart', () => {
    beforeEach(() => {
      factory();
    });

    it('passes the anomalous values correctly', () => {
      expect(findChart().props('data').anomalous.values).toMatchObject(mockAnomalousHistory);
    });

    it('passes the nominal values correctly', () => {
      expect(findChart().props('data').nominal.values).toMatchObject(mockNominalHistory);
    });
  });

  describe('given the component needs to resize', () => {
    beforeEach(() => {
      factory();
    });

    it('the chart instance is resized', () => {
      findChart().vm.$emit('created', mockChartInstance);
      expect(mockChartInstance.resize).toHaveBeenCalledTimes(0);
      MockResizeObserverDirective.simulateResize();
      expect(mockChartInstance.resize).toHaveBeenCalledTimes(1);
    });
  });

  describe('chart tooltip', () => {
    beforeEach(() => {
      const mockParams = {
        seriesData: [
          {
            seriesName: ANOMALOUS_REQUESTS,
            value: mockAnomalousHistory[0],
          },
          {
            seriesName: TOTAL_REQUESTS,
            value: mockNominalHistory[0],
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
                  <slot name="tooltip-title"></slot>
                  <slot name="tooltip-content"></slot>
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
