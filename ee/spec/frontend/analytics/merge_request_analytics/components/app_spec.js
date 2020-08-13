import { shallowMount } from '@vue/test-utils';
import MergeRequestAnalyticsApp from 'ee/analytics/merge_request_analytics/components/app.vue';
import ThroughputChart from 'ee/analytics/merge_request_analytics/components/throughput_chart.vue';
import ThroughputTable from 'ee/analytics/merge_request_analytics/components/throughput_table.vue';

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
    expect(wrapper.contains(ThroughputChart)).toBe(true);
  });

  it('displays the throughput table component', () => {
    expect(wrapper.contains(ThroughputTable)).toBe(true);
  });
});
