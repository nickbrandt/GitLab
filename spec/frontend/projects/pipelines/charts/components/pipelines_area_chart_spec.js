import { shallowMount } from '@vue/test-utils';
import Component from '~/projects/pipelines/charts/components/pipelines_area_chart.vue';
import { transformedAreaChartData } from '../mock_data';

describe('PipelinesAreaChart', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(Component, {
      propsData: {
        chartData: transformedAreaChartData,
      },
      slots: {
        default: 'Some title',
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
