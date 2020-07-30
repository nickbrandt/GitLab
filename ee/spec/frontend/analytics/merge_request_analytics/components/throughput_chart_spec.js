import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import ThroughputChart from 'ee/analytics/merge_request_analytics/components/throughput_chart.vue';

describe('ThroughputChart', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ThroughputChart);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays the chart title', () => {
    const chartTitle = wrapper.find('[data-testid="chartTitle"').text();

    expect(chartTitle).toBe('Throughput');
  });

  it('displays the chart description', () => {
    const chartDescription = wrapper.find('[data-testid="chartDescription"').text();

    expect(chartDescription).toBe(
      'The number of merge requests merged to the master branch by month.',
    );
  });

  it('displays an empty state message when there is no data', () => {
    const alert = wrapper.find(GlAlert);

    expect(alert.exists()).toBe(true);
    expect(alert.text()).toBe('There is no data available.');
  });
});
