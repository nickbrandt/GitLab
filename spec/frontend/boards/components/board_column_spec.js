import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';

import Board from '~/boards/components/board_column.vue';
import List from '~/boards/models/list';
import axios from '~/lib/utils/axios_utils';

import { TEST_HOST } from 'helpers/test_constants';
import { listObj } from 'jest/boards/mock_data';

describe('Board Column Component', () => {
  let wrapper;
  let axiosMock;

  beforeEach(() => {
    window.gon = {};
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(`${TEST_HOST}/lists/1/issues`).reply(200, { issues: [] });
  });

  afterEach(() => {
    axiosMock.restore();

    wrapper.destroy();

    localStorage.clear();
  });

  const createComponent = ({
    listType = 'backlog',
    collapsed = false,
    withLocalStorage = true,
  } = {}) => {
    const boardId = '1';

    // Making List reactive
    const list = Vue.observable(
      new List({
        ...listObj,
        list_type: listType,
        collapsed,
      }),
    );

    if (withLocalStorage) {
      localStorage.setItem(
        `boards.${boardId}.${list.type}.${list.id}.expanded`,
        (!collapsed).toString(),
      );
    }

    wrapper = shallowMount(Board, {
      propsData: {
        boardId,
        disabled: false,
        issueLinkBase: '/',
        rootPath: '/',
        list,
      },
    });
  };

  const isExpandable = () => wrapper.classes('is-expandable');
  const isCollapsed = () => wrapper.classes('is-collapsed');

  describe('Add issue button', () => {
    it('does not render when List Type is `blank`', () => {
      createComponent({ listType: 'blank' });

      expect(wrapper.find('.issue-count-badge-add-button').exists()).toBe(false);
    });

    it('does render when logged out', () => {
      createComponent();

      expect(wrapper.find('.issue-count-badge-add-button').exists()).toBe(true);
    });
  });

  describe('Given different list types', () => {
    it('is expandable when List Type is `backlog`', () => {
      createComponent({ listType: 'backlog' });

      expect(isExpandable()).toBe(true);
    });
  });

  describe('expanding / collapsing the column', () => {
    it('does not collapse when clicking the header', () => {
      createComponent();
      expect(isCollapsed()).toBe(false);
      wrapper.find('.board-header').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(isCollapsed()).toBe(false);
      });
    });

    it('collapses expanded Column when clicking the collapse icon', () => {
      createComponent();
      expect(wrapper.vm.list.isExpanded).toBe(true);
      wrapper.find('.board-title-caret').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(isCollapsed()).toBe(true);
      });
    });

    it('expands collapsed Column when clicking the expand icon', () => {
      createComponent({ collapsed: true });
      expect(isCollapsed()).toBe(true);
      wrapper.find('.board-title-caret').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(isCollapsed()).toBe(false);
      });
    });

    it("when logged in it calls list update and doesn't set localStorage", () => {
      jest.spyOn(List.prototype, 'update');
      window.gon.current_user_id = 1;

      createComponent({ withLocalStorage: false });

      wrapper.find('.board-title-caret').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.list.update).toHaveBeenCalledTimes(1);
        expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.expanded`)).toBe(null);
      });
    });

    it("when logged out it doesn't call list update and sets localStorage", () => {
      jest.spyOn(List.prototype, 'update');

      createComponent();

      wrapper.find('.board-title-caret').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.list.update).toHaveBeenCalledTimes(0);
        expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.expanded`)).toBe(
          String(wrapper.vm.list.isExpanded),
        );
      });
    });
  });
});
