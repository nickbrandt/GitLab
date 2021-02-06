import Vue from 'vue';

import WeeksHeaderItemComponent from 'ee/roadmap/components/preset_weeks/weeks_header_item.vue';
import { getTimeframeForWeeksView } from 'ee/roadmap/utils/roadmap_utils';

import { useFakeDate } from 'helpers/fake_date';
import mountComponent from 'helpers/vue_mount_component_helper';
import { mockTimeframeInitialDate } from '../../mock_data';

const mockTimeframeIndex = 0;
const mockTimeframeWeeks = getTimeframeForWeeksView(mockTimeframeInitialDate);

const createComponent = ({
  timeframeIndex = mockTimeframeIndex,
  timeframeItem = mockTimeframeWeeks[mockTimeframeIndex],
  timeframe = mockTimeframeWeeks,
}) => {
  const Component = Vue.extend(WeeksHeaderItemComponent);

  return mountComponent(Component, {
    timeframeIndex,
    timeframeItem,
    timeframe,
  });
};

describe('WeeksHeaderItemComponent', () => {
  // Some parts of this spec are dependent that the current date is > 2018
  useFakeDate(2020, 6, 3);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});
      const currentDate = new Date();

      expect(vm.currentDate.getDate()).toBe(currentDate.getDate());
    });
  });

  describe('computed', () => {
    describe('lastDayOfCurrentWeek', () => {
      it('returns date object representing last day of the week as set in `timeframeItem`', () => {
        expect(vm.lastDayOfCurrentWeek.getDate()).toBe(
          mockTimeframeWeeks[mockTimeframeIndex].getDate() + 7,
        );
      });
    });

    describe('timelineHeaderLabel', () => {
      it('returns string containing Year, Month and Date for first timeframe item of the entire timeframe', () => {
        vm = createComponent({});

        expect(vm.timelineHeaderLabel).toBe('2017 Dec 17');
      });

      it('returns string containing Year, Month and Date for timeframe item when it is first week of the year', () => {
        vm = createComponent({
          timeframeIndex: 3,
          timeframeItem: new Date(2019, 0, 6),
        });

        expect(vm.timelineHeaderLabel).toBe('2019 Jan 6');
      });

      it('returns string containing only Month and Date timeframe item when it is somewhere in the middle of timeframe', () => {
        vm = createComponent({
          timeframeIndex: mockTimeframeIndex + 1,
          timeframeItem: mockTimeframeWeeks[mockTimeframeIndex + 1],
        });

        expect(vm.timelineHeaderLabel).toBe('Dec 24');
      });
    });

    describe('timelineHeaderClass', () => {
      it('returns empty string when timeframeItem week is less than current week', () => {
        vm = createComponent({});

        expect(vm.timelineHeaderClass).toBe('');
      });

      it('returns string containing `label-dark label-bold` when current week is same as timeframeItem week', () => {
        vm = createComponent({});
        vm.currentDate = mockTimeframeWeeks[mockTimeframeIndex];

        expect(vm.timelineHeaderClass).toBe('label-dark label-bold');
      });

      it('returns string containing `label-dark` when current week is less than timeframeItem week', () => {
        const timeframeIndex = 2;
        const timeframeItem = mockTimeframeWeeks[timeframeIndex];
        vm = createComponent({
          timeframeIndex,
          timeframeItem,
        });

        [vm.currentDate] = mockTimeframeWeeks;

        expect(vm.timelineHeaderClass).toBe('label-dark');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    it('renders component container element with class `timeline-header-item`', () => {
      expect(vm.$el.classList.contains('timeline-header-item')).toBeTruthy();
    });

    it('renders item label element class `item-label` and value as `timelineHeaderLabel`', () => {
      const itemLabelEl = vm.$el.querySelector('.item-label');

      expect(itemLabelEl).not.toBeNull();
      expect(itemLabelEl.innerText.trim()).toBe('2017 Dec 17');
    });
  });
});
