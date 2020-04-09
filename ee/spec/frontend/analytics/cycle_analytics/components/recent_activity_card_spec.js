import { mount } from '@vue/test-utils';
import createFlash from '~/flash';
import RecentActivityCard from 'ee/analytics/cycle_analytics/components/recent_activity_card.vue';
import { group, recentActivityData } from '../mock_data';
import Api from 'ee/api';

jest.mock('~/flash');

describe('RecentActivityCard', () => {
  const { full_path: groupPath } = group;
  let wrapper;

  const createComponent = (additionalParams = {}) => {
    return mount(RecentActivityCard, {
      propsData: {
        groupPath,
        additionalParams,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Api, 'cycleAnalyticsSummaryData').mockResolvedValue({ data: recentActivityData });

    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('fetches the recent activity data', () => {
    expect(Api.cycleAnalyticsSummaryData).toHaveBeenCalledWith(groupPath, {});
  });

  describe('with a failing request', () => {
    beforeEach(() => {
      jest.spyOn(Api, 'cycleAnalyticsSummaryData').mockRejectedValue();

      wrapper = createComponent();
    });

    it('should render an error message', () => {
      expect(createFlash).toHaveBeenCalledWith(
        'There was an error while fetching value stream analytics recent activity data.',
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
      expect(Api.cycleAnalyticsSummaryData).toHaveBeenCalledWith(groupPath, {
        'project_ids[]': [1],
        created_after: '2020-01-01',
        created_before: '2020-02-01',
      });
    });
  });
});
