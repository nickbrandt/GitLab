import Vue from 'vue';

import roadmapShellComponent from 'ee/roadmap/components/roadmap_shell.vue';
import eventHub from 'ee/roadmap/event_hub';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockEpic, mockTimeframeInitialDate, mockGroupId } from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = (
  { epics = [mockEpic], timeframe = mockTimeframeMonths, currentGroupId = mockGroupId },
  el,
) => {
  const Component = Vue.extend(roadmapShellComponent);

  return mountComponent(
    Component,
    {
      presetType: PRESET_TYPES.MONTHS,
      epics,
      timeframe,
      currentGroupId,
    },
    el,
  );
};

describe('RoadmapShellComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.shellWidth).toBe(0);
      expect(vm.shellHeight).toBe(0);
      expect(vm.noScroll).toBe(false);
      expect(vm.timeframeStartOffset).toBe(0);
    });
  });

  describe('computed', () => {
    describe('containerStyles', () => {
      beforeEach(() => {
        document.body.innerHTML +=
          '<div class="roadmap-container"><div id="roadmap-shell"></div></div>';
      });

      afterEach(() => {
        document.querySelector('.roadmap-container').remove();
      });

      it('returns style object based on shellWidth and shellHeight', done => {
        const vmWithParentEl = createComponent({}, document.getElementById('roadmap-shell'));
        Vue.nextTick(() => {
          const stylesObj = vmWithParentEl.containerStyles;
          // Ensure that value for `width` & `height`
          // is a non-zero number.
          expect(parseInt(stylesObj.width, 10)).not.toBe(0);
          expect(parseInt(stylesObj.height, 10)).not.toBe(0);
          vmWithParentEl.$destroy();
          done();
        });
      });
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
            vmWithParentEl.noScroll = false;
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

    it('adds `prevent-vertical-scroll` class on component container element', done => {
      vm.noScroll = true;
      Vue.nextTick(() => {
        expect(vm.$el.classList.contains('prevent-vertical-scroll')).toBe(true);
        done();
      });
    });
  });
});
