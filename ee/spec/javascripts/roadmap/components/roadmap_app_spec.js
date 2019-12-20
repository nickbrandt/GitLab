import Vue from 'vue';

import appComponent from 'ee/roadmap/components/roadmap_app.vue';
import createStore from 'ee/roadmap/store';
import eventHub from 'ee/roadmap/event_hub';

import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES, EXTEND_AS } from 'ee/roadmap/constants';

import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import {
  mockTimeframeInitialDate,
  mockGroupId,
  mockNewEpicEndpoint,
  rawEpics,
  mockSvgPath,
  mockSortedBy,
  basePath,
  epicsPath,
} from '../mock_data';

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

  describe('data', () => {
    describe('when `gon.feature.roadmapGraphql` is true', () => {
      const originalGonFeatures = Object.assign({}, gon.features);

      beforeAll(() => {
        gon.features = { roadmapGraphql: true };
      });

      afterAll(() => {
        gon.features = originalGonFeatures;
      });

      it('returns data prop containing `fetchEpicsFn` mapped to `fetchEpicsGQL`', () => {
        expect(vm.fetchEpicsFn).toBe(vm.fetchEpicsGQL);
      });

      it('returns data prop containing `fetchEpicsForTimeframeFn` mapped to `fetchEpicsForTimeframeGQL`', () => {
        expect(vm.fetchEpicsForTimeframeFn).toBe(vm.fetchEpicsForTimeframeGQL);
      });
    });

    describe('when `gon.feature.roadmapGraphql` is false', () => {
      const originalGonFeatures = Object.assign({}, gon.features);

      beforeAll(() => {
        gon.features = { roadmapGraphql: false };
      });

      afterAll(() => {
        gon.features = originalGonFeatures;
      });

      it('returns data prop containing `fetchEpicsFn` mapped to `fetchEpics`', () => {
        expect(vm.fetchEpicsFn).toBe(vm.fetchEpics);
      });

      it('returns data prop containing `fetchEpicsForTimeframeFn` mapped to `fetchEpicsForTimeframe`', () => {
        expect(vm.fetchEpicsForTimeframeFn).toBe(vm.fetchEpicsForTimeframe);
      });
    });
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
      it('updates timeline by extending timeframe from the start when called with extendType as `prepend`', done => {
        vm.$store.dispatch('receiveEpicsSuccess', { rawEpics });
        vm.$store.state.epicsFetchInProgress = false;

        Vue.nextTick()
          .then(() => {
            const roadmapTimelineEl = vm.$el.querySelector('.roadmap-timeline-section');

            spyOn(eventHub, '$emit');
            spyOn(roadmapTimelineEl.parentElement, 'scrollBy');

            vm.processExtendedTimeline({
              extendType: EXTEND_AS.PREPEND,
              roadmapTimelineEl,
              itemsCount: 0,
            });

            expect(eventHub.$emit).toHaveBeenCalledWith('refreshTimeline', jasmine.any(Object));
            expect(roadmapTimelineEl.parentElement.scrollBy).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('updates timeline by extending timeframe from the end when called with extendType as `append`', done => {
        vm.$store.dispatch('receiveEpicsSuccess', { rawEpics });
        vm.$store.state.epicsFetchInProgress = false;

        Vue.nextTick()
          .then(() => {
            const roadmapTimelineEl = vm.$el.querySelector('.roadmap-timeline-section');

            spyOn(eventHub, '$emit');

            vm.processExtendedTimeline({
              extendType: EXTEND_AS.PREPEND,
              roadmapTimelineEl,
              itemsCount: 0,
            });

            expect(eventHub.$emit).toHaveBeenCalledWith('refreshTimeline', jasmine.any(Object));
          })
          .then(done)
          .catch(done.fail);
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
        spyOn(vm, 'extendTimeframe');
        spyOn(vm, 'refreshEpicDates');

        const extendType = EXTEND_AS.PREPEND;

        vm.handleScrollToExtend(roadmapTimelineEl, extendType);

        expect(vm.extendTimeframe).toHaveBeenCalledWith({ extendAs: extendType });
        expect(vm.refreshEpicDates).toHaveBeenCalled();
      });

      it('calls `fetchEpicsForTimeframe` with extended timeframe array', done => {
        spyOn(vm, 'extendTimeframe').and.stub();
        spyOn(vm, 'refreshEpicDates').and.stub();
        spyOn(vm, 'fetchEpicsForTimeframeFn').and.callFake(() => new Promise(() => {}));

        const extendType = EXTEND_AS.PREPEND;

        vm.handleScrollToExtend(roadmapTimelineEl, extendType);

        vm.$nextTick()
          .then(() => {
            expect(vm.fetchEpicsForTimeframeFn).toHaveBeenCalledWith(
              jasmine.objectContaining({
                timeframe: vm.extendedTimeframe,
              }),
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('template', () => {
    it('renders roadmap container with class `roadmap-container`', () => {
      expect(vm.$el.classList.contains('roadmap-container')).toBe(true);
    });

    it('renders roadmap container with classes `roadmap-container overflow-reset` when isEpicsListEmpty prop is true', done => {
      vm.$store.state.epicsFetchResultEmpty = true;
      Vue.nextTick()
        .then(() => {
          expect(vm.$el.classList.contains('roadmap-container')).toBe(true);
          expect(vm.$el.classList.contains('overflow-reset')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
