import { shallowMount } from '@vue/test-utils';
import { GlPopover } from '@gitlab/ui';
import StackedProgressBar from '~/vue_shared/components/stacked_progress_bar.vue';

import GeoNodeSyncProgress from 'ee/geo_nodes/components/geo_node_sync_progress.vue';

describe('GeoNodeSyncProgress', () => {
  let wrapper;

  const MOCK_ITEM_VALUE = { successCount: 5, failureCount: 3, totalCount: 10 };
  MOCK_ITEM_VALUE.queuedCount =
    MOCK_ITEM_VALUE.totalCount - MOCK_ITEM_VALUE.successCount - MOCK_ITEM_VALUE.failureCount;

  const defaultProps = {
    itemTitle: 'GitLab version',
    itemValue: MOCK_ITEM_VALUE,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(GeoNodeSyncProgress, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findStackedProgressBar = () => wrapper.find(StackedProgressBar);
  const findGlPopover = () => wrapper.find(GlPopover);
  const findCounts = () => findGlPopover().findAll('div');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders StackedProgressbar always', () => {
      expect(findStackedProgressBar().exists()).toBeTruthy();
    });

    describe('GlPopover', () => {
      it('renders always', () => {
        expect(findGlPopover().exists()).toBeTruthy();
      });

      it('renders each row of popover correctly', () => {
        findCounts().wrappers.forEach(row => {
          expect(row.element).toMatchSnapshot();
        });
      });
    });
  });

  describe('computed', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('queuedCount', () => {
      it('returns total - success - failure', () => {
        expect(wrapper.vm.queuedCount).toEqual(MOCK_ITEM_VALUE.queuedCount);
      });
    });
  });
});
