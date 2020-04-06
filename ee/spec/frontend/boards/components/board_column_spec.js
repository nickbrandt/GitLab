import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';

import Board from 'ee/boards/components/board_column.vue';
import List from '~/boards/models/list';
import { ListType } from '~/boards/constants';
import axios from '~/lib/utils/axios_utils';

import { TEST_HOST } from 'helpers/test_constants';
import { listObj } from 'jest/boards/mock_data';

// board_promotion_state tries to mount on the real DOM,
// so we are mocking it in this test
jest.mock('ee/boards/components/board_promotion_state', () => ({}));

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

  const findSettingsButton = () => wrapper.find({ ref: 'settingsBtn' });

  describe('Settings Button', () => {
    it.each(Object.values(ListType))(
      'when feature flag is off: does not render for List Type `%s`',
      listType => {
        window.gon = {
          features: {
            wipLimits: false,
          },
        };
        createComponent({ listType });

        expect(findSettingsButton().exists()).toBe(false);
      },
    );

    describe('when feature flag is on', () => {
      const hasSettings = [ListType.assignee, ListType.milestone, ListType.label];
      const hasNoSettings = [ListType.backlog, ListType.blank, ListType.closed, ListType.promotion];

      beforeEach(() => {
        window.gon = {
          features: {
            wipLimits: true,
          },
        };
      });

      it.each(hasSettings)('does render for List Type `%s`', listType => {
        createComponent({ listType });

        expect(findSettingsButton().exists()).toBe(true);
      });

      it.each(hasNoSettings)('does not render for List Type `%s`', listType => {
        createComponent({ listType });

        expect(findSettingsButton().exists()).toBe(false);
      });

      it('has a test for each list type', () => {
        Object.values(ListType).forEach(value => {
          expect([...hasSettings, ...hasNoSettings]).toContain(value);
        });
      });
    });
  });
});
