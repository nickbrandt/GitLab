import { shallowMount, createLocalVue } from '@vue/test-utils';

import epicsListSectionComponent from 'ee/roadmap/components/epics_list_section.vue';
import createStore from 'ee/roadmap/store';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';
import {
  PRESET_TYPES,
  EPIC_DETAILS_CELL_WIDTH,
  TIMELINE_CELL_MIN_WIDTH,
} from 'ee/roadmap/constants';
import {
  mockTimeframeInitialDate,
  mockGroupId,
  rawEpics,
  mockSortedBy,
  basePath,
  epicsPath,
} from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);
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

store.dispatch('receiveEpicsSuccess', { rawEpics });

const mockEpics = store.state.epics;

const createComponent = ({
  epics = mockEpics,
  timeframe = mockTimeframeMonths,
  currentGroupId = mockGroupId,
  presetType = PRESET_TYPES.MONTHS,
  roadmapBufferedRendering = true,
} = {}) => {
  const localVue = createLocalVue();

  return shallowMount(epicsListSectionComponent, {
    localVue,
    store,
    stubs: {
      'epic-item': false,
      'virtual-list': false,
    },
    propsData: {
      presetType,
      epics,
      timeframe,
      currentGroupId,
    },
    provide: {
      glFeatures: { roadmapBufferedRendering },
    },
  });
};

describe('EpicsListSectionComponent', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(wrapper.vm.offsetLeft).toBe(0);
      expect(wrapper.vm.emptyRowContainerStyles).toEqual({});
      expect(wrapper.vm.showBottomShadow).toBe(false);
      expect(wrapper.vm.roadmapShellEl).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('emptyRowContainerVisible', () => {
      it('returns true when total epics are less than buffer size', () => {
        wrapper.vm.setBufferSize(wrapper.vm.epics.length + 1);

        expect(wrapper.vm.emptyRowContainerVisible).toBe(true);
      });
    });

    describe('sectionContainerStyles', () => {
      it('returns style string for container element based on sectionShellWidth', () => {
        expect(wrapper.vm.sectionContainerStyles.width).toBe(
          `${EPIC_DETAILS_CELL_WIDTH + TIMELINE_CELL_MIN_WIDTH * wrapper.vm.timeframe.length}px`,
        );
      });
    });

    describe('shadowCellStyles', () => {
      it('returns computed style object based on `offsetLeft` prop value', () => {
        expect(wrapper.vm.shadowCellStyles.left).toBe('0px');
      });
    });
  });

  describe('methods', () => {
    describe('initMounted', () => {
      it('sets value of `roadmapShellEl` with root component element', () => {
        expect(wrapper.vm.roadmapShellEl instanceof HTMLElement).toBe(true);
      });

      it('calls action `setBufferSize` with value based on window.innerHeight and component element position', () => {
        expect(wrapper.vm.bufferSize).toBe(12);
      });

      it('sets value of `offsetLeft` with parentElement.offsetLeft', done => {
        wrapper.vm.$nextTick(() => {
          // During tests, there's no `$el.parentElement` present
          // hence offsetLeft is 0.
          expect(wrapper.vm.offsetLeft).toBe(0);
          done();
        });
      });

      it('calls `scrollToTodayIndicator` following the component render', done => {
        spyOn(wrapper.vm, 'scrollToTodayIndicator');

        // Original method implementation waits for render cycle
        // to complete at 2 levels before scrolling.
        wrapper.vm.$nextTick(() => {
          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.scrollToTodayIndicator).toHaveBeenCalled();
            done();
          });
        });
      });

      it('sets style object to `emptyRowContainerStyles`', done => {
        wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.emptyRowContainerStyles).toEqual(
            jasmine.objectContaining({
              height: '0px',
            }),
          );
          done();
        });
      });
    });

    describe('getEmptyRowContainerStyles', () => {
      it('returns empty object when there are no epics available to render', () => {
        wrapper.setProps({
          epics: [],
        });

        expect(wrapper.vm.getEmptyRowContainerStyles()).toEqual({});
      });

      it('returns object containing `height` when there epics available to render', () => {
        expect(wrapper.vm.getEmptyRowContainerStyles()).toEqual(
          jasmine.objectContaining({
            height: '0px',
          }),
        );
      });
    });

    describe('handleEpicsListScroll', () => {
      it('toggles value of `showBottomShadow` based on provided `scrollTop`, `clientHeight` & `scrollHeight`', () => {
        wrapper.vm.handleEpicsListScroll({
          scrollTop: 5,
          clientHeight: 5,
          scrollHeight: 15,
        });

        // Math.ceil(scrollTop) + clientHeight < scrollHeight
        expect(wrapper.vm.showBottomShadow).toBe(true);

        wrapper.vm.handleEpicsListScroll({
          scrollTop: 15,
          clientHeight: 5,
          scrollHeight: 15,
        });

        // Math.ceil(scrollTop) + clientHeight < scrollHeight
        expect(wrapper.vm.showBottomShadow).toBe(false);
      });
    });

    describe('getEpicItemProps', () => {
      it('returns an object containing props for EpicItem component', () => {
        expect(wrapper.vm.getEpicItemProps(1)).toEqual(
          jasmine.objectContaining({
            key: 1,
            props: {
              epic: wrapper.vm.epics[1],
              presetType: wrapper.vm.presetType,
              timeframe: wrapper.vm.timeframe,
              currentGroupId: wrapper.vm.currentGroupId,
            },
          }),
        );
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `epics-list-section`', () => {
      expect(wrapper.vm.$el.classList.contains('epics-list-section')).toBe(true);
    });

    it('renders virtual-list when roadmapBufferedRendering is `true` and `epics.length` is more than `bufferSize`', () => {
      wrapper.vm.setBufferSize(5);

      expect(wrapper.find('virtuallist-stub').exists()).toBe(true);
    });

    it('renders epic-item when roadmapBufferedRendering is `false`', () => {
      const wrapperFlagOff = createComponent({
        roadmapBufferedRendering: false,
      });

      expect(wrapperFlagOff.find('epicitem-stub').exists()).toBe(true);

      wrapperFlagOff.destroy();
    });

    it('renders epic-item when roadmapBufferedRendering is `true` and `epics.length` is less than `bufferSize`', () => {
      wrapper.vm.setBufferSize(50);

      expect(wrapper.find('epicitem-stub').exists()).toBe(true);
    });

    it('renders empty row element when `epics.length` is less than `bufferSize`', () => {
      wrapper.vm.setBufferSize(50);

      expect(wrapper.find('.epics-list-item-empty').exists()).toBe(true);
    });

    it('renders bottom shadow element when `showBottomShadow` prop is true', () => {
      wrapper.setData({
        showBottomShadow: true,
      });

      expect(wrapper.find('.scroll-bottom-shadow').exists()).toBe(true);
    });
  });
});
