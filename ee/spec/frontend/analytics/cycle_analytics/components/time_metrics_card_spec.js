import { shallowMount } from '@vue/test-utils';
import createFlash from '~/flash';
import TimeMetricsCard from 'ee/analytics/cycle_analytics/components/time_metrics_card.vue';
import { group, timeMetricsData } from '../mock_data';
import Api from 'ee/api';

jest.mock('~/flash');

describe('TimeMetricsCard', () => {
  const { full_path: groupPath } = group;
  let wrapper;

  const createComponent = ({ additionalParams = {} } = {}) => {
    return shallowMount(TimeMetricsCard, {
      propsData: {
        groupPath,
        additionalParams,
      },
      slots: {
        default: 'mockMetricCard',
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Api, 'cycleAnalyticsTimeSummaryData').mockResolvedValue({ data: timeMetricsData });

    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });
  it('fetches the time metrics data', () => {
    expect(Api.cycleAnalyticsTimeSummaryData).toHaveBeenCalledWith(groupPath, {});
  });

  describe('with a failing request', () => {
    beforeEach(() => {
      jest.spyOn(Api, 'cycleAnalyticsTimeSummaryData').mockRejectedValue();

      wrapper = createComponent();
    });

    it('should render an error message', () => {
      expect(createFlash).toHaveBeenCalledWith(
        'There was an error while fetching value stream analytics time summary data.',
      );
    });
  });

  describe('with additional params', () => {
    beforeEach(() => {
      wrapper = createComponent({
        additionalParams: {
          'project_ids[]': [1],
          created_after: '2020-01-01',
          created_before: '2020-02-01',
        },
      });
    });

    it('sends additional parameters as query paremeters', () => {
      expect(Api.cycleAnalyticsTimeSummaryData).toHaveBeenCalledWith(groupPath, {
        'project_ids[]': [1],
        created_after: '2020-01-01',
        created_before: '2020-02-01',
      });
    });
  });
});
