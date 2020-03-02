// NOTE: more tests will be added in https://gitlab.com/gitlab-org/gitlab/issues/121613
import { shallowMount } from '@vue/test-utils';
import StageNavItem from 'ee/analytics/cycle_analytics/components/stage_nav_item.vue';
import { approximateDuration } from '~/lib/utils/datetime_utility';

describe('StageNavItem', () => {
  const title = 'Rad stage';
  const median = 50;

  function createComponent(props) {
    return shallowMount(StageNavItem, {
      propsData: {
        title,
        value: median,
        ...props,
      },
    });
  }

  let wrapper = null;
  const findStageTitle = () => wrapper.find({ ref: 'title' });
  const findStageMedian = () => wrapper.find({ ref: 'median' });

  afterEach(() => {
    wrapper.destroy();
  });

  it('with no median value', () => {
    wrapper = createComponent({ value: null });
    expect(findStageMedian().text()).toEqual('Not enough data');
  });

  describe('with data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the median value', () => {
      expect(findStageMedian().text()).toEqual(approximateDuration(median));
    });

    it('renders the stage title', () => {
      expect(findStageTitle().text()).toEqual(title);
    });
  });
});
