import { mount } from '@vue/test-utils';
import { GlSkeletonLoading } from '@gitlab/ui';
import MetricCard from 'ee/analytics/shared/components/metric_card.vue';

const defaultProps = {
  title: 'My fancy title',
  metrics: [
    { key: 'first_metric', value: 10, label: 'First metric' },
    { key: 'second_metric', value: 20, label: 'Yet another metric' },
    { key: 'third_metric', value: null, label: 'Metric without value' },
  ],
  isLoading: false,
};

describe('MetricCard', () => {
  let wrapper;

  const factory = (props = defaultProps) => {
    wrapper = mount(MetricCard, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findTitle = () => wrapper.find({ ref: 'title' });
  const findLoadingIndicator = () => wrapper.find(GlSkeletonLoading);
  const findMetricsWrapper = () => wrapper.find({ ref: 'metricsWrapper' });
  const findMetricItem = () => wrapper.findAll({ ref: 'metricItem' });

  describe('template', () => {
    it('renders the title', () => {
      factory();

      expect(findTitle().text()).toContain('My fancy title');
    });

    describe('when isLoading is true', () => {
      beforeEach(() => {
        factory({ isLoading: true });
      });

      it('displays a loading indicator', () => {
        expect(findLoadingIndicator().exists()).toBe(true);
      });

      it('does not display the metrics container', () => {
        expect(findMetricsWrapper().exists()).toBe(false);
      });
    });

    describe('when isLoading is false', () => {
      beforeEach(() => {
        factory({ isLoading: false });
      });

      it('does not display a loading indicator', () => {
        expect(findLoadingIndicator().exists()).toBe(false);
      });

      it('displays the metrics container', () => {
        expect(findMetricsWrapper().exists()).toBe(true);
      });

      it('renders two metrics', () => {
        expect(findMetricItem()).toHaveLength(3);
      });

      describe.each`
        columnIndex | label                     | value
        ${0}        | ${'First metric'}         | ${10}
        ${1}        | ${'Yet another metric'}   | ${20}
        ${2}        | ${'Metric without value'} | ${'-'}
      `('metric columns', ({ columnIndex, label, value }) => {
        it(`renders "${label}" as label`, () => {
          expect(
            findMetricItem()
              .at(columnIndex)
              .text(),
          ).toContain(label);
        });

        it(`renders ${value} as value`, () => {
          expect(
            findMetricItem()
              .at(columnIndex)
              .text(),
          ).toContain(value);
        });
      });
    });
  });
});
