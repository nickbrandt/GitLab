import Vue from 'vue';

import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

import appComponent from 'ee/roadmap/components/app.vue';
import RoadmapStore from 'ee/roadmap/store/roadmap_store';
import RoadmapService from 'ee/roadmap/service/roadmap_service';
import eventHub from 'ee/roadmap/event_hub';

import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES, EXTEND_AS } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import {
  mockTimeframeInitialDate,
  mockGroupId,
  basePath,
  epicsPath,
  mockNewEpicEndpoint,
  rawEpics,
  mockSvgPath,
  mockSortedBy,
} from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = () => {
  const Component = Vue.extend(appComponent);
  const timeframe = mockTimeframeMonths;

  const store = new RoadmapStore({
    groupId: mockGroupId,
    presetType: PRESET_TYPES.MONTHS,
    sortedBy: mockSortedBy,
    timeframe,
  });

  const service = new RoadmapService({
    initialEpicsPath: epicsPath,
    epicsState: 'all',
    basePath,
  });

  return mountComponent(Component, {
    store,
    service,
    presetType: PRESET_TYPES.MONTHS,
    hasFiltersApplied: true,
    newEpicEndpoint: mockNewEpicEndpoint,
    emptyStateIllustrationPath: mockSvgPath,
  });
};

describe('AppComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.isLoading).toBe(false);
      expect(vm.isEpicsListEmpty).toBe(false);
      expect(vm.hasError).toBe(false);
      expect(vm.handleResizeThrottled).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('epics', () => {
      it('returns array of epics', () => {
        expect(Array.isArray(vm.epics)).toBe(true);
      });
    });

    describe('timeframe', () => {
      it('returns array of timeframe', () => {
        expect(Array.isArray(vm.timeframe)).toBe(true);
      });
    });

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

    describe('currentGroupId', () => {
      it('returns current group Id', () => {
        expect(vm.currentGroupId).toBe(mockGroupId);
      });
    });

    describe('showRoadmap', () => {
      it('returns true if `isLoading`, `isEpicsListEmpty` and `hasError` are all `false`', () => {
        vm.isLoading = false;
        vm.isEpicsListEmpty = false;
        vm.hasError = false;

        expect(vm.showRoadmap).toBe(true);
      });

      it('returns false if either of `isLoading`, `isEpicsListEmpty` and `hasError` is `true`', () => {
        vm.isLoading = true;
        vm.isEpicsListEmpty = false;
        vm.hasError = false;

        expect(vm.showRoadmap).toBe(false);
        vm.isLoading = false;
        vm.isEpicsListEmpty = true;
        vm.hasError = false;

        expect(vm.showRoadmap).toBe(false);
        vm.isLoading = false;
        vm.isEpicsListEmpty = false;
        vm.hasError = true;

        expect(vm.showRoadmap).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('fetchEpics', () => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);
        document.body.innerHTML += '<div class="flash-container"></div>';
      });

      afterEach(() => {
        mock.restore();
        document.querySelector('.flash-container').remove();
      });

      it('calls service.getEpics and sets response to the store on success', done => {
        mock.onGet(vm.service.epicsPath).reply(200, rawEpics);
        spyOn(vm.store, 'setEpics');
        spyOn(eventHub, '$emit');

        vm.fetchEpics();

        expect(vm.hasError).toBe(false);
        setTimeout(() => {
          expect(vm.isLoading).toBe(false);
          expect(vm.store.setEpics).toHaveBeenCalledWith(rawEpics);

          vm.$nextTick()
            .then(() => {
              expect(eventHub.$emit).toHaveBeenCalledWith(
                'refreshTimeline',
                jasmine.objectContaining({
                  todayBarReady: true,
                  initialRender: true,
                }),
              );
            })
            .then(done)
            .catch(done.fail);
        }, 0);
      });

      it('calls service.getEpics and sets `isEpicsListEmpty` to true if response is empty', done => {
        mock.onGet(vm.service.epicsPath).reply(200, []);
        spyOn(vm.store, 'setEpics');

        vm.fetchEpics();

        expect(vm.isEpicsListEmpty).toBe(false);
        setTimeout(() => {
          expect(vm.isEpicsListEmpty).toBe(true);
          expect(vm.store.setEpics).not.toHaveBeenCalled();
          done();
        }, 0);
      });

      it('calls service.getEpics and sets `hasError` to true and shows flash message if request failed', done => {
        mock.onGet(vm.service.epicsPath).reply(500, {});

        vm.fetchEpics();

        expect(vm.hasError).toBe(false);
        setTimeout(() => {
          expect(vm.hasError).toBe(true);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe(
            'Something went wrong while fetching epics',
          );
          done();
        }, 0);
      });
    });

    describe('fetchEpicsForTimeframe', () => {
      const roadmapTimelineEl = {
        offsetTop: 0,
      };
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);
        document.body.innerHTML += '<div class="flash-container"></div>';
      });

      afterEach(() => {
        mock.restore();
        document.querySelector('.flash-container').remove();
      });

      it('calls service.fetchEpicsForTimeframe and adds response to the store on success', done => {
        mock.onGet(vm.service.epicsPath).reply(200, rawEpics);

        const extendType = EXTEND_AS.APPEND;

        spyOn(vm.service, 'getEpicsForTimeframe').and.callThrough();
        spyOn(vm.store, 'addEpics');
        spyOn(vm, 'processExtendedTimeline');

        vm.fetchEpicsForTimeframe({
          timeframe: mockTimeframeMonths,
          extendType,
          roadmapTimelineEl,
        });

        expect(vm.hasError).toBe(false);
        expect(vm.service.getEpicsForTimeframe).toHaveBeenCalledWith(
          PRESET_TYPES.MONTHS,
          mockTimeframeMonths,
        );
        setTimeout(() => {
          expect(vm.store.addEpics).toHaveBeenCalledWith(rawEpics);
          vm.$nextTick()
            .then(() => {
              expect(vm.processExtendedTimeline).toHaveBeenCalledWith(
                jasmine.objectContaining({
                  itemsCount: 8,
                  extendType,
                  roadmapTimelineEl,
                }),
              );
            })
            .then(done)
            .catch(done.fail);
        }, 0);
      });

      it('calls service.fetchEpicsForTimeframe and sets `hasError` to true and shows flash message when request failed', done => {
        mock.onGet(vm.service.fetchEpicsForTimeframe).reply(500, {});

        vm.fetchEpicsForTimeframe({
          timeframe: mockTimeframeMonths,
          extendType: EXTEND_AS.APPEND,
          roadmapTimelineEl,
        });

        expect(vm.hasError).toBe(false);
        setTimeout(() => {
          expect(vm.hasError).toBe(true);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe(
            'Something went wrong while fetching epics',
          );
          done();
        }, 0);
      });
    });

    describe('processExtendedTimeline', () => {
      it('updates timeline by extending timeframe from the start when called with extendType as `prepend`', done => {
        vm.store.setEpics(rawEpics);
        vm.isLoading = false;

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
        vm.store.setEpics(rawEpics);
        vm.isLoading = false;

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
      beforeEach(() => {
        vm.store.setEpics(rawEpics);
        vm.isLoading = false;
      });

      it('updates the store and refreshes roadmap with extended timeline when called with `extendType` param as `prepend`', done => {
        spyOn(vm.store, 'extendTimeframe');
        spyOn(vm, 'fetchEpicsForTimeframe');

        const extendType = EXTEND_AS.PREPEND;
        const roadmapTimelineEl = vm.$el.querySelector('.roadmap-timeline-section');

        vm.handleScrollToExtend(roadmapTimelineEl, extendType);

        expect(vm.store.extendTimeframe).toHaveBeenCalledWith(extendType);

        vm.$nextTick()
          .then(() => {
            expect(vm.fetchEpicsForTimeframe).toHaveBeenCalledWith(
              jasmine.objectContaining({
                // During tests, we don't extend timeframe
                // as we spied on `vm.store.extendTimeframe` above
                timeframe: undefined,
                roadmapTimelineEl,
                extendType,
              }),
            );
          })
          .then(done)
          .catch(done.fail);
      });

      it('updates the store and refreshes roadmap with extended timeline when called with `extendType` param as `append`', done => {
        spyOn(vm.store, 'extendTimeframe');
        spyOn(vm, 'fetchEpicsForTimeframe');

        const extendType = EXTEND_AS.APPEND;
        const roadmapTimelineEl = vm.$el.querySelector('.roadmap-timeline-section');

        vm.handleScrollToExtend(roadmapTimelineEl, extendType);

        expect(vm.store.extendTimeframe).toHaveBeenCalledWith(extendType);

        vm.$nextTick()
          .then(() => {
            expect(vm.fetchEpicsForTimeframe).toHaveBeenCalledWith(
              jasmine.objectContaining({
                // During tests, we don't extend timeframe
                // as we spied on `vm.store.extendTimeframe` above
                timeframe: undefined,
                roadmapTimelineEl,
                extendType,
              }),
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('mounted', () => {
    it('binds window resize event listener', () => {
      spyOn(window, 'addEventListener');
      const vmX = createComponent();

      expect(vmX.handleResizeThrottled).toBeDefined();
      expect(window.addEventListener).toHaveBeenCalledWith(
        'resize',
        vmX.handleResizeThrottled,
        false,
      );
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds window resize event listener', () => {
      spyOn(window, 'removeEventListener');
      const vmX = createComponent();
      vmX.$destroy();

      expect(window.removeEventListener).toHaveBeenCalledWith(
        'resize',
        vmX.handleResizeThrottled,
        false,
      );
    });
  });

  describe('template', () => {
    it('renders roadmap container with class `roadmap-container`', () => {
      expect(vm.$el.classList.contains('roadmap-container')).toBe(true);
    });

    it('renders roadmap container with classes `roadmap-container overflow-reset` when isEpicsListEmpty prop is true', done => {
      vm.isEpicsListEmpty = true;
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
