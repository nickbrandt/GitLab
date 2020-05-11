import { mount } from '@vue/test-utils';
import createFlash from '~/flash';
import TimeMetricsCard from 'ee/analytics/cycle_analytics/components/time_metrics_card.vue';
import { group, timeMetricsData } from '../mock_data';
import Api from 'ee/api';

jest.mock('~/flash');

describe('TimeMetricsCard', () => {
  const { full_path: groupPath } = group;
  let wrapper;

  const createComponent = (additionalParams = {}) => {
    return mount(TimeMetricsCard, {
      propsData: {
        groupPath,
        additionalParams,
      },
    });
  };

  const findMetricCards = () => wrapper.findAll('.js-metric-card-item');

  beforeEach(() => {
    jest.spyOn(Api, 'cycleAnalyticsTimeSummaryData').mockResolvedValue({ data: timeMetricsData });

    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('fetches the time metrics data', () => {
    expect(Api.cycleAnalyticsTimeSummaryData).toHaveBeenCalledWith(groupPath, {});
  });

  describe('with data', () => {
    it.each`
      metric          | value         | index
      ${'Lead time'}  | ${'2 days'}   | ${0}
      ${'Cycle time'} | ${'1.5 days'} | ${1}
    `('Renders the $metric', ({ metric, value, index }) => {
      const card = findMetricCards().at(index);
      expect(card.html()).toContain(metric);
      expect(card.html()).toContain(value);
    });
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
        'project_ids[]': [1],
        created_after: '2020-01-01',
        created_before: '2020-02-01',
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
