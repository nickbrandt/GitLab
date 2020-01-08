import { shallowMount } from '@vue/test-utils';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import createStore from 'ee/threat_monitoring/store';
import WafStatisticsSummary from 'ee/threat_monitoring/components/waf_statistics_summary.vue';
import { mockWafStatisticsResponse } from '../mock_data';

describe('WafStatisticsSummary component', () => {
  let store;
  let wrapper;

  const factory = state => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, state);

    wrapper = shallowMount(WafStatisticsSummary, {
      store,
      sync: false,
    });
  };

  const findAnomalousStat = () => wrapper.findAll(GlSingleStat).at(0);
  const findNominalStat = () => wrapper.findAll(GlSingleStat).at(1);

  beforeEach(() => {
    factory({
      wafStatistics: {
        totalTraffic: mockWafStatisticsResponse.total_traffic,
        anomalousTraffic: mockWafStatisticsResponse.anomalous_traffic,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the anomalous traffic percentage', () => {
    expect(findAnomalousStat().element).toMatchSnapshot();
  });

  it('renders the nominal traffic count', () => {
    expect(findNominalStat().element).toMatchSnapshot();
  });
});
