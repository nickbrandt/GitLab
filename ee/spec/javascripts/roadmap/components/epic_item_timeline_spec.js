import Vue from 'vue';

import epicItemTimelineComponent from 'ee/roadmap/components/epic_item_timeline.vue';
import eventHub from 'ee/roadmap/event_hub';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { TIMELINE_CELL_MIN_WIDTH, PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeInitialDate, mockEpic, mockShellWidth, mockItemWidth } from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  timeframe = mockTimeframeMonths,
  timeframeItem = mockTimeframeMonths[0],
  epic = mockEpic,
  shellWidth = mockShellWidth,
  itemWidth = mockItemWidth,
}) => {
  const Component = Vue.extend(epicItemTimelineComponent);

  return mountComponent(Component, {
    presetType,
    timeframe,
    timeframeItem,
    epic,
    shellWidth,
    itemWidth,
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

      expect(vm.timelineBarReady).toBe(false);
      expect(vm.timelineBarStyles).toBe('');
    });
  });

  describe('computed', () => {
    describe('itemStyles', () => {
      it('returns CSS min-width based on getCellWidth() method', () => {
        vm = createComponent({});

        expect(vm.itemStyles.width).toBe(`${mockItemWidth}px`);
      });
    });
  });

  describe('methods', () => {
    describe('getCellWidth', () => {
      it('returns proportionate width based on timeframe length and shellWidth', () => {
        vm = createComponent({});

        expect(vm.getCellWidth()).toBe(210);
      });

      it('returns minimum fixed width when proportionate width available lower than minimum fixed width defined', () => {
        vm = createComponent({
          shellWidth: 1000,
        });

        expect(vm.getCellWidth()).toBe(TIMELINE_CELL_MIN_WIDTH);
      });
    });

    describe('renderTimelineBar', () => {
      it('sets `timelineBarStyles` & `timelineBarReady` when timeframeItem has Epic.startDate', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, { startDate: mockTimeframeMonths[1] }),
          timeframeItem: mockTimeframeMonths[1],
        });
        vm.renderTimelineBar();

        expect(vm.timelineBarStyles).toBe('width: 1274px; left: 0;');
        expect(vm.timelineBarReady).toBe(true);
      });

      it('does not set `timelineBarStyles` & `timelineBarReady` when timeframeItem does NOT have Epic.startDate', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, { startDate: mockTimeframeMonths[0] }),
          timeframeItem: mockTimeframeMonths[1],
        });
        vm.renderTimelineBar();

        expect(vm.timelineBarStyles).toBe('');
        expect(vm.timelineBarReady).toBe(false);
      });
    });
  });

  describe('mounted', () => {
    it('binds `refreshTimeline` event listener on eventHub', () => {
      spyOn(eventHub, '$on');
      const vmX = createComponent({});

      expect(eventHub.$on).toHaveBeenCalledWith('refreshTimeline', jasmine.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `refreshTimeline` event listener on eventHub', () => {
      spyOn(eventHub, '$off');
      const vmX = createComponent({});
      vmX.$destroy();

      expect(eventHub.$off).toHaveBeenCalledWith('refreshTimeline', jasmine.any(Function));
    });
  });

  describe('template', () => {
    it('renders component container element with class `epic-timeline-cell`', () => {
      vm = createComponent({});

      expect(vm.$el.classList.contains('epic-timeline-cell')).toBe(true);
    });

    it('renders component container element with `min-width` property applied via style attribute', () => {
      vm = createComponent({});

      expect(vm.$el.getAttribute('style')).toBe(`width: ${mockItemWidth}px;`);
    });

    it('renders timeline bar element with class `timeline-bar` and class `timeline-bar-wrapper` as container element', () => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, { startDate: mockTimeframeMonths[1] }),
        timeframeItem: mockTimeframeMonths[1],
      });

      expect(vm.$el.querySelector('.timeline-bar-wrapper .timeline-bar')).not.toBeNull();
    });

    it('renders timeline bar with calculated `width` and `left` properties applied via style attribute', done => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, {
          startDate: mockTimeframeMonths[0],
          endDate: new Date(2018, 1, 15),
        }),
      });
      const timelineBarEl = vm.$el.querySelector('.timeline-bar-wrapper .timeline-bar');

      vm.renderTimelineBar();
      vm.$nextTick(() => {
        expect(timelineBarEl.getAttribute('style')).toBe('width: 742.5px; left: 0px;');
        done();
      });
    });

    it('renders timeline bar with `start-date-undefined` class when Epic startDate is undefined', done => {
      vm = createComponent({
        epic: Object.assign({}, mockEpic, {
          startDateUndefined: true,
          startDate: mockTimeframeMonths[0],
        }),
      });
      const timelineBarEl = vm.$el.querySelector('.timeline-bar-wrapper .timeline-bar');

      vm.renderTimelineBar();
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

      vm.renderTimelineBar();
      vm.$nextTick(() => {
        expect(timelineBarEl.classList.contains('end-date-undefined')).toBe(true);
        done();
      });
    });
  });
});
