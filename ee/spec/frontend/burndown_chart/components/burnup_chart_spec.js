import { shallowMount } from '@vue/test-utils';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';
import BurnupChart from 'ee/burndown_chart/components/burnup_chart.vue';

describe('Burnup chart', () => {
  let wrapper;

  const defaultProps = {
    startDate: '2019-08-07T00:00:00.000Z',
    dueDate: '2019-09-09T00:00:00.000Z',
  };

  const findChart = () => wrapper.find(GlLineChart);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BurnupChart, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        ResizableChartContainer,
      },
    });
  };

  it.each`
    scope
    ${[{ '2019-08-07T00:00:00.000Z': 100 }]}
    ${[{ '2019-08-07T00:00:00.000Z': 100 }, { '2019-08-08T00:00:00.000Z': 99 }, { '2019-09-08T00:00:00.000Z': 1 }]}
  `('renders the lineChart correctly', ({ scope }) => {
    createComponent({ scope });
    const chartData = findChart().props('data');

    expect(chartData).toEqual([
      {
        name: 'Total',
        data: scope,
      },
    ]);
  });

  it('only shows integers on axis labels', () => {
    const msInOneDay = 60 * 60 * 24 * 1000;
    expect(findChart().props('option')).toMatchObject({
      xAxis: {
        type: 'time',
        minInterval: msInOneDay,
      },
      yAxis: {
        minInterval: 1,
      },
    });
  });

  it('does not show average or max values in legend', () => {
    expect(findChart().props('includeLegendAvgMax')).toBe(false);
  });
});
