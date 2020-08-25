import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import BoardColumn from 'ee_else_ce/boards/components/board_column.vue';
import getters from 'ee/boards/stores/getters';
import { mockListsWithModel, mockIssuesByListId } from '../mock_data';
import BoardContent from '~/boards/components/board_content.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('BoardContent', () => {
  let wrapper;

  const defaultState = {
    isShowingEpicsSwimlanes: false,
    boardLists: mockListsWithModel,
    error: undefined,
    issuesByListId: mockIssuesByListId,
  };

  const createStore = (state = defaultState) => {
    return new Vuex.Store({
      state,
      actions: {
        fetchIssuesForAllLists: () => {},
      },
      getters,
    });
  };

  const createComponent = state => {
    const store = createStore({
      ...defaultState,
      ...state,
    });
    wrapper = shallowMount(BoardContent, {
      localVue,
      propsData: {
        lists: mockListsWithModel,
        canAdminList: true,
        groupId: 1,
        disabled: false,
        issueLinkBase: '/',
        rootPath: '/',
        boardId: '1',
      },
      store,
      provide: {
        glFeatures: { boardsWithSwimlanes: true },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Swimlanes off', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a BoardColumn component per list', () => {
      expect(wrapper.findAll(BoardColumn)).toHaveLength(mockListsWithModel.length);
    });

    it('does not display EpicsSwimlanes component', () => {
      expect(wrapper.contains(EpicsSwimlanes)).toBe(false);
      expect(wrapper.contains(GlAlert)).toBe(false);
    });
  });

  describe('Swimlanes on', () => {
    beforeEach(() => {
      createComponent({ isShowingEpicsSwimlanes: true });
    });

    it('does not display BoardColumn component', () => {
      expect(wrapper.findAll(BoardColumn)).toHaveLength(0);
    });

    it('displays EpicsSwimlanes component', () => {
      expect(wrapper.contains('.board-swimlanes')).toBe(true);
      expect(wrapper.contains(GlAlert)).toBe(false);
    });

    it('displays alert if an error occurs when fetching swimlanes', () => {
      createComponent({
        isShowingEpicsSwimlanes: true,
        error: 'An error occurred while fetching the board swimlanes. Please reload the page.',
      });

      expect(wrapper.contains(GlAlert)).toBe(true);
    });
  });
});
