import { mount } from '@vue/test-utils';
import { GlSkeletonLoading } from '@gitlab/ui';
import MetricCard from 'ee/analytics/shared/components/metric_card.vue';

const metrics = [
  { key: 'first_metric', value: 10, label: 'First metric', unit: 'days' },
  { key: 'second_metric', value: 20, label: 'Yet another metric' },
  { key: 'third_metric', value: null, label: 'Null metric without value', unit: 'parsecs' },
  { key: 'fourth_metric', value: '-', label: 'Metric without value', unit: 'parsecs' },
];

const defaultProps = {
  title: 'My fancy title',
  isLoading: false,
  metrics,
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
        expect(findMetricItem()).toHaveLength(metrics.length);
      });

      describe.each`
        columnIndex | label                          | value  | unit
        ${0}        | ${'First metric'}              | ${10}  | ${' days'}
        ${1}        | ${'Yet another metric'}        | ${20}  | ${''}
        ${2}        | ${'Null metric without value'} | ${'-'} | ${''}
        ${3}        | ${'Metric without value'}      | ${'-'} | ${''}
      `('metric columns', ({ columnIndex, label, value, unit }) => {
        it(`renders ${value}${unit} ${label}`, () => {
          expect(
            findMetricItem()
              .at(columnIndex)
              .text(),
          ).toEqual(`${value}${unit} ${label}`);
        });
      });
    });
  });
});
