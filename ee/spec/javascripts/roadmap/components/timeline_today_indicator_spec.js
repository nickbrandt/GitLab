import Vue from 'vue';

import timelineTodayIndicatorComponent from 'ee/roadmap/components/timeline_today_indicator.vue';
import eventHub from 'ee/roadmap/event_hub';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeInitialDate } from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const mockCurrentDate = new Date(
  mockTimeframeMonths[0].getFullYear(),
  mockTimeframeMonths[0].getMonth(),
  15,
);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  currentDate = mockCurrentDate,
  timeframeItem = mockTimeframeMonths[0],
}) => {
  const Component = Vue.extend(timelineTodayIndicatorComponent);

  return mountComponent(Component, {
    presetType,
    currentDate,
    timeframeItem,
  });
};

describe('TimelineTodayIndicatorComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});

      expect(vm.todayBarStyles).toBe('');
      expect(vm.todayBarReady).toBe(false);
    });
  });

  describe('methods', () => {
    describe('handleEpicsListRender', () => {
      it('sets `todayBarStyles` and `todayBarReady` props', () => {
        vm = createComponent({});
        vm.handleEpicsListRender({});
        const stylesObj = vm.todayBarStyles;

        expect(stylesObj.height).toBe('600px');
        expect(stylesObj.left).toBe('50%');
        expect(vm.todayBarReady).toBe(true);
      });

      it('sets `todayBarReady` prop based on value of provided `todayBarReady` param', () => {
        vm = createComponent({});
        vm.handleEpicsListRender({
          todayBarReady: false,
        });

        expect(vm.todayBarReady).toBe(false);
      });
    });
  });

  describe('mounted', () => {
    it('binds `epicsListRendered`, `epicsListScrolled` and `refreshTimeline` event listeners via eventHub', () => {
      spyOn(eventHub, '$on');
      const vmX = createComponent({});

      expect(eventHub.$on).toHaveBeenCalledWith('epicsListRendered', jasmine.any(Function));
      expect(eventHub.$on).toHaveBeenCalledWith('epicsListScrolled', jasmine.any(Function));
      expect(eventHub.$on).toHaveBeenCalledWith('refreshTimeline', jasmine.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `epicsListRendered`, `epicsListScrolled` and `refreshTimeline` event listeners via eventHub', () => {
      spyOn(eventHub, '$off');
      const vmX = createComponent({});
      vmX.$destroy();

      expect(eventHub.$off).toHaveBeenCalledWith('epicsListRendered', jasmine.any(Function));
      expect(eventHub.$off).toHaveBeenCalledWith('epicsListScrolled', jasmine.any(Function));
      expect(eventHub.$off).toHaveBeenCalledWith('refreshTimeline', jasmine.any(Function));
    });
  });

  describe('template', () => {
    it('renders component container element with class `today-bar`', done => {
      vm = createComponent({});
      vm.handleEpicsListRender({});
      vm.$nextTick(() => {
        expect(vm.$el.classList.contains('today-bar')).toBe(true);
        done();
      });
    });
  });
});
