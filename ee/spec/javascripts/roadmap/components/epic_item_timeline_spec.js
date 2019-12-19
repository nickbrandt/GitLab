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
}) => {
  const Component = Vue.extend(epicItemTimelineComponent);

  return mountComponent(Component, {
    presetType,
    timeframe,
    timeframeItem,
    epic,
  });
};

describe('EpicItemTimelineComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});

      expect(vm.epicStartDateValues).toEqual(
        jasmine.objectContaining({
          day: mockEpic.startDate.getDay(),
          date: mockEpic.startDate.getDate(),
          month: mockEpic.startDate.getMonth(),
          year: mockEpic.startDate.getFullYear(),
          time: mockEpic.startDate.getTime(),
        }),
      );

      expect(vm.epicEndDateValues).toEqual(
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

  describe('template', () => {
    it('renders component container element with class `epic-timeline-cell`', () => {
      vm = createComponent({});

      expect(vm.$el.classList.contains('epic-timeline-cell')).toBe(true);
    });

    it('renders timeline bar element with class `timeline-bar` and class `timeline-bar-wrapper` as container element', () => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, { startDate: mockTimeframeMonths[1] }),
        timeframeItem: mockTimeframeMonths[1],
      });

      expect(vm.$el.querySelector('.timeline-bar-wrapper .timeline-bar')).not.toBeNull();
    });

    it('renders timeline bar with calculated `width` and `left` properties applied via style attribute', () => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, {
          startDate: mockTimeframeMonths[0],
          endDate: new Date(2018, 1, 15),
        }),
      });
      const timelineBarEl = vm.$el.querySelector('.timeline-bar-wrapper .timeline-bar');

      expect(timelineBarEl.getAttribute('style')).toContain('width');
      expect(timelineBarEl.getAttribute('style')).toContain('left: 0px;');
    });

    it('renders timeline bar with `start-date-undefined` class when Epic startDate is undefined', done => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, {
          startDateUndefined: true,
          startDate: mockTimeframeMonths[0],
        }),
      });
      const timelineBarEl = vm.$el.querySelector('.timeline-bar-wrapper .timeline-bar');

      vm.$nextTick(() => {
        expect(timelineBarEl.classList.contains('start-date-undefined')).toBe(true);
        done();
      });
    });

    it('renders timeline bar with `end-date-undefined` class when Epic endDate is undefined', done => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, {
          startDate: mockTimeframeMonths[0],
          endDateUndefined: true,
          endDate: mockTimeframeMonths[mockTimeframeMonths.length - 1],
        }),
      });
      const timelineBarEl = vm.$el.querySelector('.timeline-bar-wrapper .timeline-bar');

      vm.$nextTick(() => {
        expect(timelineBarEl.classList.contains('end-date-undefined')).toBe(true);
        done();
      });
    });
  });
});
