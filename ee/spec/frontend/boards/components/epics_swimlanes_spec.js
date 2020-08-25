import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Draggable from 'vuedraggable';
import EpicsSwimlanes from 'ee/boards/components/epics_swimlanes.vue';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import EpicLane from 'ee/boards/components/epic_lane.vue';
import IssueLaneList from 'ee/boards/components/issues_lane_list.vue';
import getters from 'ee/boards/stores/getters';
import { draggableTag } from 'ee/boards/constants';
import { GlIcon } from '@gitlab/ui';
import { mockListsWithModel, mockEpics, mockIssuesByListId, issues } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EpicsSwimlanes', () => {
  let wrapper;

  const createStore = () => {
    return new Vuex.Store({
      actions: {
        fetchIssuesForAllLists: jest.fn(),
      },
      state: {
        epics: mockEpics,
        isLoadingIssues: false,
        issuesByListId: mockIssuesByListId,
        issues,
      },
      getters,
    });
  };

  const createComponent = (props = {}) => {
    const store = createStore();
    const defaultProps = {
      lists: mockListsWithModel,
      boardId: '1',
      disabled: false,
      rootPath: '/',
    };

    wrapper = shallowMount(EpicsSwimlanes, {
      localVue,
      propsData: { ...defaultProps, ...props },
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('treeRootWrapper', () => {
      it('should return Draggable reference when canAdminList prop is true', () => {
        wrapper.setProps({ canAdminList: true });

        expect(wrapper.vm.treeRootWrapper).toBe(Draggable);
      });

      it('should return string "div" when canAdminList prop is false', () => {
        expect(wrapper.vm.treeRootWrapper).toBe(draggableTag);
      });
    });

    describe('treeRootOptions', () => {
      it('should return object containing Vue.Draggable config extended from `defaultSortableConfig` when canAdminList prop is true', () => {
        wrapper.setProps({ canAdminList: true });

        expect(wrapper.vm.treeRootOptions).toEqual(
          expect.objectContaining({
            animation: 200,
            forceFallback: true,
            fallbackClass: 'is-dragging',
            fallbackOnBody: false,
            ghostClass: 'is-ghost',
            group: 'board-swimlanes',
            tag: draggableTag,
            draggable: '.is-draggable',
            'ghost-class': 'swimlane-header-drag-active',
            value: mockListsWithModel,
          }),
        );
      });

      it('should return an empty object when canAdminList prop is false', () => {
        expect(wrapper.vm.treeRootOptions).toEqual(expect.objectContaining({}));
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays BoardListHeader components for lists', () => {
      expect(wrapper.findAll(BoardListHeader)).toHaveLength(2);
    });

    it('displays EpicLane components for epic', () => {
      expect(wrapper.findAll(EpicLane)).toHaveLength(5);
    });

    it('displays IssueLaneList component', () => {
      expect(wrapper.find(IssueLaneList).exists()).toBe(true);
    });

    it('displays issues icon and count for unassigned issue', () => {
      expect(wrapper.find(GlIcon).props('name')).toEqual('issues');
      expect(wrapper.find('[data-testid="issues-lane-issue-count"]').text()).toEqual('2');
    });

    it('makes non preset lists draggable', () => {
      expect(
        wrapper
          .findAll('[data-testid="board-header-container"]')
          .at(1)
          .classes(),
      ).toContain('is-draggable');
    });

    it('does not make preset lists draggable', () => {
      expect(
        wrapper
          .findAll('[data-testid="board-header-container"]')
          .at(0)
          .classes(),
      ).not.toContain('is-draggable');
    });
  });
});
