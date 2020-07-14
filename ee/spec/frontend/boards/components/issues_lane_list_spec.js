import Vue from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { shallowMount } from '@vue/test-utils';
import IssuesLaneList from 'ee/boards/components/issues_lane_list.vue';
import BoardCard from '~/boards/components/board_card.vue';
import { mockIssues } from '../mock_data';
import List from '~/boards/models/list';
import { ListType } from '~/boards/constants';
import { listObj } from 'jest/boards/mock_data';
import { TEST_HOST } from 'helpers/test_constants';

describe('IssuesLaneList', () => {
  let wrapper;
  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(`${TEST_HOST}/lists/1/issues`).reply(200, { issues: [] });
  });

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    withLocalStorage = true,
  } = {}) => {
    const boardId = '1';

    const listMock = {
      ...listObj,
      list_type: listType,
      collapsed,
    };

    if (listType === ListType.assignee) {
      delete listMock.label;
      listMock.user = {};
    }

    // Making List reactive
    const list = Vue.observable(new List(listMock));

    if (withLocalStorage) {
      localStorage.setItem(
        `boards.${boardId}.${list.type}.${list.id}.expanded`,
        (!collapsed).toString(),
      );
    }

    wrapper = shallowMount(IssuesLaneList, {
      propsData: {
        list,
        issues: mockIssues,
      },
    });
  };

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
    localStorage.clear();
  });

  describe('if list is expanded', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not have is-collapsed class', () => {
      expect(wrapper.classes('is-collapsed')).toBe(false);
    });

    it('renders one BoardCard component per issue passed in props', () => {
      expect(wrapper.findAll(BoardCard)).toHaveLength(wrapper.props('issues').length);
    });
  });

  describe('if list is collapsed', () => {
    beforeEach(() => {
      createComponent({ collapsed: true });
    });

    it('has is-collapsed class', () => {
      expect(wrapper.classes('is-collapsed')).toBe(true);
    });

    it('does not renders BoardCard components', () => {
      expect(wrapper.findAll(BoardCard)).toHaveLength(0);
    });
  });
});
