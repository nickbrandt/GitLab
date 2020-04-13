import Vue from 'vue';

import appComponent from 'ee/roadmap/components/roadmap_app.vue';
import createStore from 'ee/roadmap/store';
import eventHub from 'ee/roadmap/event_hub';

import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES, EXTEND_AS } from 'ee/roadmap/constants';

import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import {
  mockTimeframeInitialDate,
  mockGroupId,
  mockNewEpicEndpoint,
  rawEpics,
  mockSvgPath,
  mockSortedBy,
  basePath,
  epicsPath,
} from 'ee_jest/roadmap/mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = () => {
  const Component = Vue.extend(appComponent);

  const store = createStore();
  store.dispatch('setInitialData', {
    currentGroupId: mockGroupId,
    sortedBy: mockSortedBy,
    presetType: PRESET_TYPES.MONTHS,
    timeframe: mockTimeframeMonths,
    filterQueryString: '',
    initialEpicsPath: epicsPath,
    basePath,
  });

  return mountComponentWithStore(Component, {
    store,
    props: {
      presetType: PRESET_TYPES.MONTHS,
      hasFiltersApplied: true,
      newEpicEndpoint: mockNewEpicEndpoint,
      emptyStateIllustrationPath: mockSvgPath,
    },
  });
};

describe('Roadmap AppComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('timeframeStart', () => {
      it('returns first item of timeframe array', () => {
        expect(vm.timeframeStart instanceof Date).toBe(true);
      });
    });

    describe('timeframeEnd', () => {
      it('returns last item of timeframe array', () => {
        expect(vm.timeframeEnd instanceof Date).toBe(true);
      });
    });

    describe('showRoadmap', () => {
      it('returns true if `windowResizeInProgress`, `epicsFetchInProgress`, `epicsFetchResultEmpty` and `epicsFetchFailure` are all `false`', () => {
        vm.$store.state.windowResizeInProgress = false;
        vm.$store.state.epicsFetchInProgress = false;
        vm.$store.state.epicsFetchResultEmpty = false;
        vm.$store.state.epicsFetchFailure = false;

        expect(vm.showRoadmap).toBe(true);
      });

      it('returns false if either of `windowResizeInProgress`, `epicsFetchInProgress`, `epicsFetchResultEmpty` and `epicsFetchFailure` is `true`', () => {
        vm.$store.state.windowResizeInProgress = true;
        vm.$store.state.epicsFetchInProgress = false;
        vm.$store.state.epicsFetchResultEmpty = false;
        vm.$store.state.epicsFetchFailure = false;

        expect(vm.showRoadmap).toBe(false);

        vm.$store.state.windowResizeInProgress = false;
        vm.$store.state.epicsFetchInProgress = true;
        vm.$store.state.epicsFetchResultEmpty = false;
        vm.$store.state.epicsFetchFailure = false;

        expect(vm.showRoadmap).toBe(false);

        vm.$store.state.windowResizeInProgress = false;
        vm.$store.state.epicsFetchInProgress = false;
        vm.$store.state.epicsFetchResultEmpty = true;
        vm.$store.state.epicsFetchFailure = false;

        expect(vm.showRoadmap).toBe(false);

        vm.$store.state.windowResizeInProgress = false;
        vm.$store.state.epicsFetchInProgress = false;
        vm.$store.state.epicsFetchResultEmpty = false;
        vm.$store.state.epicsFetchFailure = true;

        expect(vm.showRoadmap).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('processExtendedTimeline', () => {
      it('updates timeline by extending timeframe from the start when called with extendType as `prepend`', () => {
        vm.$store.dispatch('receiveEpicsSuccess', { rawEpics });
        vm.$store.state.epicsFetchInProgress = false;

        return Vue.nextTick().then(() => {
          const roadmapTimelineEl = vm.$el.querySelector('.roadmap-timeline-section');

          jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

          vm.processExtendedTimeline({
            extendType: EXTEND_AS.PREPEND,
            roadmapTimelineEl,
            itemsCount: 0,
          });

          expect(eventHub.$emit).toHaveBeenCalledWith('refreshTimeline', expect.any(Object));
          expect(roadmapTimelineEl.parentElement.scrollBy).toHaveBeenCalled();
        });
      });

      it('updates timeline by extending timeframe from the end when called with extendType as `append`', () => {
        vm.$store.dispatch('receiveEpicsSuccess', { rawEpics });
        vm.$store.state.epicsFetchInProgress = false;

        return Vue.nextTick().then(() => {
          const roadmapTimelineEl = vm.$el.querySelector('.roadmap-timeline-section');

          jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

          vm.processExtendedTimeline({
            extendType: EXTEND_AS.PREPEND,
            roadmapTimelineEl,
            itemsCount: 0,
          });

          expect(eventHub.$emit).toHaveBeenCalledWith('refreshTimeline', expect.any(Object));
        });
      });
    });

    describe('handleScrollToExtend', () => {
      let roadmapTimelineEl;

      beforeAll(() => {
        vm.$store.dispatch('receiveEpicsSuccess', { rawEpics });
        vm.$store.state.epicsFetchInProgress = false;
        roadmapTimelineEl = vm.$el.querySelector('.roadmap-timeline-section');
      });

      it('updates the store and refreshes roadmap with extended timeline based on provided extendType', () => {
        jest.spyOn(vm, 'extendTimeframe').mockImplementation(() => {});
        jest.spyOn(vm, 'refreshEpicDates').mockImplementation(() => {});
        jest.spyOn(vm, 'refreshMilestoneDates').mockImplementation(() => {});
        jest.spyOn(vm, 'fetchEpicsForTimeframe').mockResolvedValue();

        const extendType = EXTEND_AS.PREPEND;

        vm.handleScrollToExtend(roadmapTimelineEl, extendType);

        expect(vm.extendTimeframe).toHaveBeenCalledWith({ extendAs: extendType });
        expect(vm.refreshEpicDates).toHaveBeenCalled();
        expect(vm.refreshMilestoneDates).toHaveBeenCalled();
      });

      it('calls `fetchEpicsForTimeframe` with extended timeframe array', () => {
        jest.spyOn(vm, 'extendTimeframe').mockImplementation(() => {});
        jest.spyOn(vm, 'refreshEpicDates').mockImplementation(() => {});
        jest.spyOn(vm, 'refreshMilestoneDates').mockImplementation(() => {});
        jest.spyOn(vm, 'fetchEpicsForTimeframe').mockResolvedValue();

        const extendType = EXTEND_AS.PREPEND;

        vm.handleScrollToExtend(roadmapTimelineEl, extendType);

        return vm.$nextTick().then(() => {
          expect(vm.fetchEpicsForTimeframe).toHaveBeenCalledWith(
            expect.objectContaining({
              timeframe: vm.extendedTimeframe,
            }),
          );
        });
      });
    });
  });

  describe('template', () => {
    it('renders roadmap container with class `roadmap-container`', () => {
      expect(vm.$el.classList.contains('roadmap-container')).toBe(true);
    });

    it('renders roadmap container with classes `roadmap-container overflow-reset` when isEpicsListEmpty prop is true', () => {
      vm.$store.state.epicsFetchResultEmpty = true;

      return Vue.nextTick().then(() => {
        expect(vm.$el.classList.contains('roadmap-container')).toBe(true);
        expect(vm.$el.classList.contains('overflow-reset')).toBe(true);
      });
    });
  });
});
