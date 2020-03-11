import Vue from 'vue';

import epicItemTimelineComponent from 'ee/roadmap/components/epic_item_timeline.vue';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeInitialDate, mockEpic } from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  timeframe = mockTimeframeMonths,
  timeframeItem = mockTimeframeMonths[0],
  epic = mockEpic,
  timeframeString = '',
}) => {
  const Component = Vue.extend(epicItemTimelineComponent);

  return mountComponent(Component, {
    presetType,
    timeframe,
    timeframeItem,
    epic,
    timeframeString,
  });
};

describe('EpicItemTimelineComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    describe('startDateValues', () => {
      it('returns object containing date parts from epic.startDate', () => {
        expect(vm.startDateValues).toEqual(
          jasmine.objectContaining({
            day: mockEpic.startDate.getDay(),
            date: mockEpic.startDate.getDate(),
            month: mockEpic.startDate.getMonth(),
            year: mockEpic.startDate.getFullYear(),
            time: mockEpic.startDate.getTime(),
          }),
        );
      });
    });

    describe('endDateValues', () => {
      it('returns object containing date parts from epic.endDate', () => {
        expect(vm.endDateValues).toEqual(
          jasmine.objectContaining({
            day: mockEpic.endDate.getDay(),
            date: mockEpic.endDate.getDate(),
            month: mockEpic.endDate.getMonth(),
            year: mockEpic.endDate.getFullYear(),
            time: mockEpic.endDate.getTime(),
          }),
        );
      });
    });

    describe('epicTotalWeight', () => {
      it('returns the correct percentage of completed to total weights', () => {
        vm = createComponent({});

        expect(vm.epicTotalWeight).toBe(5);
      });

      it('returns undefined if weights information is not present', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, {
            descendantWeightSum: undefined,
          }),
        });

        expect(vm.epicTotalWeight).toBe(undefined);
      });
    });

    describe('epicWeightPercentage', () => {
      it('returns the correct percentage of completed to total weights', () => {
        vm = createComponent({});

        expect(vm.epicWeightPercentage).toBe(60);
      });

      it('returns 0 when there is no total weight', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, {
            descendantWeightSum: undefined,
          }),
        });

        expect(vm.epicWeightPercentage).toBe(0);
      });
    });

    describe('popoverWeightText', () => {
      it('returns a description of the weight completed', () => {
        vm = createComponent({});

        expect(vm.popoverWeightText).toBe('3 of 5 weight completed');
      });

      it('returns a description with no numbers for weight completed when there is no weights information', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, {
            descendantWeightSum: undefined,
          }),
        });

        expect(vm.popoverWeightText).toBe('- of - weight completed');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `epic-timeline-cell`', () => {
      vm = createComponent({});

      expect(vm.$el.classList.contains('epic-timeline-cell')).toBe(true);
    });

    it('renders current day indicator element', () => {
      const currentDate = new Date();
      vm = createComponent({
        timeframeItem: new Date(currentDate.getFullYear(), currentDate.getMonth(), 1),
      });

      expect(vm.$el.querySelector('span.current-day-indicator')).not.toBeNull();
    });

    it('renders timeline bar element with class `epic-bar` and class `epic-bar-wrapper` as container element', () => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, { startDate: mockTimeframeMonths[1] }),
        timeframeItem: mockTimeframeMonths[1],
      });

      expect(vm.$el.querySelector('.epic-bar-wrapper .epic-bar')).not.toBeNull();
    });

    it('renders timeline bar with calculated `width` and `left` properties applied via style attribute', () => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, {
          startDate: mockTimeframeMonths[0],
          endDate: new Date(2018, 1, 15),
        }),
      });
      const timelineBarEl = vm.$el.querySelector('.epic-bar-wrapper .epic-bar');

      expect(timelineBarEl.getAttribute('style')).toContain('width');
      expect(timelineBarEl.getAttribute('style')).toContain('left: 0px;');
    });

    it('renders component with the title in the epic bar', () => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, { startDate: mockTimeframeMonths[1] }),
        timeframeItem: mockTimeframeMonths[1],
      });

      expect(vm.$el.querySelector('.epic-bar').textContent).toContain(mockEpic.title);
    });
  });
});
