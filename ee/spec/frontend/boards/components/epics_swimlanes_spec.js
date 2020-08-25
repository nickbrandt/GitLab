import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import EpicsSwimlanes from 'ee/boards/components/epics_swimlanes.vue';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import EpicLane from 'ee/boards/components/epic_lane.vue';
import IssueLaneList from 'ee/boards/components/issues_lane_list.vue';
import getters from 'ee/boards/stores/getters';
import { GlIcon } from '@gitlab/ui';
import { mockListsWithModel, mockEpics, mockIssuesByListId } from '../mock_data';

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
      },
      getters,
    });
  };

  const createComponent = () => {
    const store = createStore();
    const defaultProps = {
      lists: mockListsWithModel,
      boardId: '1',
      disabled: false,
      rootPath: '/',
    };

    wrapper = shallowMount(EpicsSwimlanes, {
      localVue,
      propsData: defaultProps,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
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
      expect(wrapper.contains(IssueLaneList)).toBe(true);
    });

    it('displays issues icon and count for unassigned issue', () => {
      expect(wrapper.find(GlIcon).props('name')).toEqual('issues');
      expect(wrapper.find('[data-testid="issues-lane-issue-count"').text()).toEqual('2');
    });
  });
});
