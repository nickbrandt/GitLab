import { mount } from '@vue/test-utils';

import { delay } from 'lodash';

import EpicItemComponent from 'ee/roadmap/components/epic_item.vue';
import EpicItemContainer from 'ee/roadmap/components/epic_item_container.vue';

import { PRESET_TYPES } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import {
  mockTimeframeInitialDate,
  mockEpic,
  mockGroupId,
  mockFormattedChildEpic1,
} from 'ee_jest/roadmap/mock_data';

import { timelineBarTestCases } from 'ee_jest/roadmap/roadmap_item_test_cases';

jest.mock('lodash/delay', () =>
  jest.fn(func => {
    // eslint-disable-next-line no-param-reassign
    func.delay = jest.fn();
    return func;
  }),
);

let store;

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  epic = mockEpic,
  timeframe = mockTimeframeMonths,
  currentGroupId = mockGroupId,
  childLevel = 0,
  childrenEpics = {},
  childrenFlags = { '1': { itemExpanded: false } },
  hasFiltersApplied = false,
}) => {
  return mount(EpicItemComponent, {
    store,
    stubs: {
      'roadmap-timeline-grid': '<div></div>',
      'epic-item-container': EpicItemContainer,
      'epic-item': EpicItemComponent,
    },
    propsData: {
      presetType,
      epic,
      timeframe,
      currentGroupId,
      childLevel,
      childrenEpics,
      childrenFlags,
      hasFiltersApplied,
    },
  });
};

describe('EpicItemComponent', () => {
  let wrapper;

  const findEpicBar = () => wrapper.find('[data-testid="epic-bar"]');

  beforeEach(() => {
    store = createStore();
    wrapper = createComponent({});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('methods', () => {
    describe('removeHighlight', () => {
      it('should wait 3 seconds before toggling `epic.newEpic` from true to false', () => {
        wrapper.setProps({
          epic: {
            ...wrapper.vm.epic,
            newEpic: true,
          },
        });

        wrapper.vm.removeHighlight();

        return wrapper.vm.$nextTick().then(() => {
          expect(delay).toHaveBeenCalledWith(expect.any(Function), 3000);
        });
      });
    });
  });

  describe('template', () => {
    it('renders Epic item container', () => {
      expect(wrapper.find('.epics-list-item').exists()).toBe(true);
    });

    it('renders Epic item details element with class `epic-details-cell`', () => {
      expect(wrapper.find('.epic-details-cell').exists()).toBe(true);
    });

    describe('Epic item timeline bar', () => {
      it('is rendered', () => {
        expect(wrapper.find('[data-testid="epic-timeline-bar"]').exists()).toBe(true);
      });

      describe.each(timelineBarTestCases)('style', ({ when, propsData, expected }) => {
        describe(`when ${when}`, () => {
          beforeEach(() => {
            const { presetType, item: epic, timeframe } = propsData;
            wrapper = createComponent({
              presetType,
              epic: { ...epic, id: 'gid://gitlab/Epic/41' },
              timeframe,
              childLevel: 0,
              childrenEpics: {},
              childrenFlags: { 'gid://gitlab/Epic/41': { itemExpanded: false } },
              hasFiltersApplied: false,
            });
          });

          it('is rendered with correct width and left offset', () => {
            const epicBar = findEpicBar();
            const { width, left } = epicBar.element.style;

            expect(width).toBe(expected.width);
            expect(left).toBe(expected.left);
          });
        });
      });
    });

    it('does not render Epic item container element with class `epic-list-item-container` if epic is not expanded', () => {
      expect(wrapper.find('.epic-list-item-container').exists()).toBe(false);
    });

    it('renders Epic item container element with class `epic-list-item-container` if epic has children and is expanded', () => {
      wrapper = createComponent({
        childrenEpics: {
          '1': [mockFormattedChildEpic1],
        },
        childrenFlags: {
          '1': { itemExpanded: true },
          '50': { itemExpanded: false },
        },
      });
      expect(wrapper.find('.epic-list-item-container').exists()).toBe(true);
    });
  });
});
