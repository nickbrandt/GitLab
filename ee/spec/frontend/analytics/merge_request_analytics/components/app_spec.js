import { shallowMount } from '@vue/test-utils';
import MergeRequestAnalyticsApp from 'ee/analytics/merge_request_analytics/components/app.vue';
import ThroughputChart from 'ee/analytics/merge_request_analytics/components/throughput_chart.vue';

describe('MergeRequestAnalyticsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(MergeRequestAnalyticsApp);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays the page title', () => {
    const pageTitle = wrapper.find('[data-testid="pageTitle"').text();

    expect(pageTitle).toBe('Merge Request Analytics');
  });

  it('displays the throughput chart component', () => {
    const throughputChartComponent = wrapper.find(ThroughputChart);

    expect(throughputChartComponent.exists()).toBe(true);
  });
});
