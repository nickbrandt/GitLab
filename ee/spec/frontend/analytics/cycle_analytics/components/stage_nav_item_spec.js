// NOTE: more tests will be added in https://gitlab.com/gitlab-org/gitlab/issues/121613
import { GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StageNavItem from 'ee/analytics/cycle_analytics/components/stage_nav_item.vue';
import { approximateDuration } from '~/lib/utils/datetime_utility';

describe('StageNavItem', () => {
  const title = 'Rad stage';
  const median = 50;
  const id = 1;

  function createComponent({ props = {}, opts = {} } = {}) {
    return shallowMount(StageNavItem, {
      propsData: {
        id,
        title,
        value: median,
        ...props,
      },
      ...opts,
    });
  }

  let wrapper = null;
  const findStageTitle = () => wrapper.find({ ref: 'title' });
  const findStageMedian = () => wrapper.find({ ref: 'median' });

  afterEach(() => {
    wrapper.destroy();
  });

  it('with no median value', () => {
    wrapper = createComponent({ props: { value: null } });
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

  describe('with a really long name', () => {
    const longTitle = 'This is a very long stage name that is intended to break the ui';

    beforeEach(() => {
      wrapper = createComponent({
        props: { title: longTitle },
        opts: {
          data() {
            return { isTitleOverflowing: true };
          },
          methods: {
            // making tbis a noop so it wont toggle 'isTitleOverflowing' on mount
            checkIfTitleOverflows: () => {},
          },
        },
      });
    });

    it('renders the tooltip', () => {
      expect(wrapper.find(GlTooltip).exists()).toBe(true);
    });

    it('tooltip has the correct stage title', () => {
      expect(wrapper.find(GlTooltip).text()).toBe(longTitle);
    });
  });
});
