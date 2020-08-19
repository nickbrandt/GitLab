import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import BoardContent from 'ee_component/boards/components/board_content.vue';
import List from '~/boards/models/list';
import BoardColumn from 'ee_component/boards/components/board_column.vue';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import defaultState from 'ee_component/boards/stores/state';
import { mockLists } from '../mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('ee/BoardContent', () => {
  let store;
  let wrapper;
  let mock;

  const createStore = (state = defaultState()) => {
    store = new Vuex.Store({
      state,
      actions: {
        fetchIssuesForAllLists: () => {},
      },
    });
  };

  const createComponent = (boardsWithSwimlanes = false) => {
    wrapper = mount(BoardContent, {
      localVue,
      store,
      propsData: {
        lists: mockLists.map(listMock => new List(listMock)),
        canAdminList: true,
        groupId: 1,
        disabled: false,
        issueLinkBase: '',
        rootPath: '',
        boardId: '',
      },
      provide: {
        glFeatures: {
          boardsWithSwimlanes,
        },
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('when isSwimlanes and boardsWithSwimlanes', () => {
    beforeEach(() => {
      createStore();

      store.state.isShowingEpicsSwimlanes = true;

      createComponent(true);
    });

    it('renders EpicsSwimlanes', () => {
      expect(wrapper.find(EpicsSwimlanes).exists()).toBe(true);
    });
  });

  it('finds BoardColumns', () => {
    createStore();

    createComponent();

    expect(wrapper.findAll(BoardColumn).length).toBe(mockLists.length);
  });
});
