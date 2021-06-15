import { shallowMount } from '@vue/test-utils';
import StatisticsSummary from 'ee/threat_monitoring/components/statistics_summary.vue';

describe('StatisticsSummary component', () => {
  let wrapper;

  const factory = (options) => {
    wrapper = shallowMount(StatisticsSummary, {
      stubs: { GlSingleStat: true },
      ...options,
    });
  };

  const findAnomalousStat = () => wrapper.findAll('glsinglestat-stub').at(0);
  const findNominalStat = () => wrapper.findAll('glsinglestat-stub').at(1);

  beforeEach(() => {
    factory({
      propsData: {
        data: {
          anomalous: { title: 'Anomalous', value: 0.2 },
          nominal: { title: 'Total', value: 100 },
        },
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
