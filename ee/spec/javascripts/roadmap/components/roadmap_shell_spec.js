import Vue from 'vue';

import roadmapShellComponent from 'ee/roadmap/components/roadmap_shell.vue';
import createStore from 'ee/roadmap/store';
import eventHub from 'ee/roadmap/event_hub';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { mockEpic, mockTimeframeInitialDate, mockGroupId } from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = (
  {
    epics = [mockEpic],
    timeframe = mockTimeframeMonths,
    currentGroupId = mockGroupId,
    defaultInnerHeight = 0,
  },
  el,
) => {
  const Component = Vue.extend(roadmapShellComponent);

  const store = createStore();
  store.dispatch('setInitialData', {
    defaultInnerHeight,
  });

  return mountComponentWithStore(Component, {
    el,
    store,
    props: {
      presetType: PRESET_TYPES.MONTHS,
      epics,
      timeframe,
      currentGroupId,
    },
  });
};

describe('RoadmapShellComponent', () => {
  let vm;

  beforeEach(done => {
    vm = createComponent({});
    vm.$nextTick(done);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.timeframeStartOffset).toBe(0);
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      document.body.innerHTML +=
        '<div class="roadmap-container"><div id="roadmap-shell"></div></div>';
    });

    afterEach(() => {
      document.querySelector('.roadmap-container').remove();
    });

    describe('handleScroll', () => {
      it('emits `epicsListScrolled` event via eventHub', done => {
        const vmWithParentEl = createComponent({}, document.getElementById('roadmap-shell'));
        spyOn(eventHub, '$emit');

        Vue.nextTick()
          .then(() => {
            vmWithParentEl.handleScroll();

            expect(eventHub.$emit).toHaveBeenCalledWith('epicsListScrolled', jasmine.any(Object));

            vmWithParentEl.$destroy();
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `roadmap-shell`', () => {
      expect(vm.$el.classList.contains('roadmap-shell')).toBe(true);
    });

    it('renders skeleton loader element when Epics list is empty', done => {
      vm.epics = [];

      vm.$nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.js-skeleton-loader')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
