import { shallowMount } from '@vue/test-utils';
import MergeRequestAnalyticsApp from 'ee/analytics/merge_request_analytics/components/app.vue';
import FilterBar from 'ee/analytics/merge_request_analytics/components/filter_bar.vue';
import ThroughputChart from 'ee/analytics/merge_request_analytics/components/throughput_chart.vue';
import ThroughputTable from 'ee/analytics/merge_request_analytics/components/throughput_table.vue';
import DateRange from '~/analytics/shared/components/daterange.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

describe('MergeRequestAnalyticsApp', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(MergeRequestAnalyticsApp, {
      propsData: {
        startDate: new Date('2020-05-01'),
        endDate: new Date('2020-10-01'),
      },
    });
  }

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

  it('displays the filter bar component', () => {
    expect(wrapper.find(FilterBar).exists()).toBe(true);
  });

  it('displays the date range component', () => {
    expect(wrapper.find(DateRange).exists()).toBe(true);
  });

  it('displays the throughput chart component', () => {
    expect(wrapper.find(ThroughputChart).exists()).toBe(true);
  });

  it('displays the throughput table component', () => {
    expect(wrapper.find(ThroughputTable).exists()).toBe(true);
  });

  describe('url sync', () => {
    it('includes the url sync component', () => {
      expect(wrapper.find(UrlSync).exists()).toBe(true);
    });

    it('has the start and end date params', () => {
      const urlSync = wrapper.find(UrlSync);

      expect(urlSync.props('query')).toMatchObject({
        start_date: '2020-05-01',
        end_date: '2020-10-01',
      });
    });
  });
});
