import '~/boards/models/list';
import MockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlDrawer, GlLabel, GlButton, GlFormInput } from '@gitlab/ui';
import BoardSettingsSidebar from 'ee/boards/components/board_settings_sidebar.vue';
import boardsStore from 'ee_else_ce/boards/stores/boards_store_ee';
import getters from 'ee_else_ce/boards/stores/getters';
import bs from '~/boards/stores/boards_store';
import flash from '~/flash';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/flash');
// NOTE: needed for calling boardsStore.addList

const localVue = createLocalVue();

localVue.use(Vuex);

describe('BoardSettingsSideBar', () => {
  let wrapper;
  let mock;
  let storeActions;
  const labelTitle = 'test';
  const labelColor = '#FFFF';
  const listId = 1;

  const createComponent = (state = {}, actions = {}, localState = {}) => {
    storeActions = actions;

    const store = new Vuex.Store({
      state,
      actions: storeActions,
      getters,
    });

    wrapper = shallowMount(BoardSettingsSidebar, {
      store,
      localVue,
      data() {
        return localState;
      },
      sync: false,
    });
  };

  const triggerBlur = type => {
    if (type === 'blur') {
      wrapper.find(GlFormInput).vm.$emit('blur');
    }

    if (type === 'enter') {
      wrapper.find(GlFormInput).trigger('keydown.enter');
    }
  };

  beforeEach(() => {
    // mock CE store
    const storeMock = {
      state: { lists: [] },
      create() {},
      setCurrentBoard: jest.fn(),
      findList: bs.findList,
      addList: bs.addList,
      removeList: bs.removeList,
    };

    boardsStore.initEESpecific(storeMock);
  });

  afterEach(() => {
    jest.restoreAllMocks();
    wrapper.destroy();
  });

  describe('GlDrawer', () => {
    it('finds a GlDrawer component', () => {
      createComponent();

      expect(wrapper.find(GlDrawer).exists()).toBe(true);
    });

    describe('on close', () => {
      it('calls closeSidebar', done => {
        const spy = jest.fn();
        createComponent({}, { setActiveListId: spy });

        wrapper.find(GlDrawer).vm.$emit('close');

        return wrapper.vm
          .$nextTick()
          .then(() => {
            expect(storeActions.setActiveListId).toHaveBeenCalledWith(
              expect.anything(),
              0,
              undefined,
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('when activeListId is zero', () => {
      it('renders GlDrawer with open false', () => {
        createComponent();

        expect(wrapper.find(GlDrawer).props('open')).toBe(false);
      });
    });

    describe('when activeListId is greater than zero', () => {
      it('renders GlDrawer with open false', () => {
        createComponent({ activeListId: 1 });

        expect(wrapper.find(GlDrawer).props('open')).toBe(true);
      });
    });

    describe('when activeListId is in boardsStore', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);

        boardsStore.store.addList({
          id: listId,
          label: { title: labelTitle, color: labelColor },
          list_type: 'label',
        });

        createComponent({ activeListId: listId });
      });

      afterEach(() => {
        mock.restore();
      });

      it('renders label title', () => {
        expect(wrapper.find(GlLabel).props('title')).toEqual(labelTitle);
      });

      it('renders label background color', () => {
        expect(wrapper.find(GlLabel).props('backgroundColor')).toEqual(labelColor);
      });
    });

    describe('when activeListId is not in boardsStore', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);

        boardsStore.store.addList({ id: listId, label: { title: labelTitle, color: labelColor } });

        createComponent({ activeListId: 0 });
      });

      afterEach(() => {
        mock.restore();
      });

      it('renders label title', () => {
        expect(wrapper.find(GlLabel).props('title')).toEqual('');
      });

      it('renders label background color', () => {
        expect(wrapper.find(GlLabel).props('backgroundColor')).toEqual('');
      });
    });
  });

  describe('when activeList is present', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      boardsStore.store.removeList(listId);
    });

    describe('when activeListWipLimit is 0', () => {
      beforeEach(() => {
        boardsStore.store.addList({
          id: listId,
          label: { title: labelTitle, color: labelColor },
          max_issue_count: 0,
          list_type: 'label',
        });
      });

      it('renders "None" in the block', () => {
        createComponent({ activeListId: listId });

        expect(wrapper.find('.js-wip-limit').text()).toMatchSnapshot();
      });
    });

    describe('when activeListWipLimit is greater than 0', () => {
      it.each`
        num
        ${1}
        ${11}
      `('it renders $num', ({ num }) => {
        boardsStore.store.addList({
          id: num,
          label: { title: labelTitle, color: labelColor },
          max_issue_count: num,
          list_type: 'label',
        });

        createComponent({ activeListId: num });

        expect(wrapper.find('.js-wip-limit').text()).toMatchSnapshot();
      });
    });
  });

  describe('when clicking edit', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      boardsStore.store.addList({
        id: listId,
        label: { title: labelTitle, color: labelColor },
        max_issue_count: 4,
        list_type: 'label',
      });

      createComponent({ activeListId: listId });
    });

    it('renders an input', done => {
      wrapper.find(GlButton).vm.$emit('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.find(GlFormInput).exists()).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not render current wipLimit text', done => {
      wrapper.find(GlButton).vm.$emit('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.find('.js-wip-limit').exists()).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });

    it('sets wipLimit to be the value of list.maxIssueCount', done => {
      expect(wrapper.vm.currentWipLimit).toEqual(0);

      wrapper.find(GlButton).vm.$emit('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.currentWipLimit).toBe(4);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when edit is true', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);

      boardsStore.store.addList({
        id: listId,
        label: { title: labelTitle, color: labelColor },
        max_issue_count: 2,
        list_type: 'label',
      });
    });

    afterEach(() => {
      flash.mockReset();
      boardsStore.store.removeList(listId, 'label');
    });

    describe.each`
      blurMethod
      ${'enter'}
      ${'blur'}
    `('$blurMethod', ({ blurMethod }) => {
      describe(`when blur is triggered by ${blurMethod}`, () => {
        it('calls updateListWipLimit', () => {
          const spy = jest.fn().mockResolvedValue({
            config: { data: JSON.stringify({ list: { max_issue_count: 'hello' } }) },
          });
          createComponent({ activeListId: 1 }, { updateListWipLimit: spy }, { edit: true });

          triggerBlur(blurMethod);

          return wrapper.vm.$nextTick().then(() => {
            expect(spy).toHaveBeenCalledTimes(1);
          });
        });

        describe('when component wipLimit and List.maxIssueCount are equal', () => {
          it('doesnt call updateListWipLimit', () => {
            const spy = jest.fn(() =>
              Promise.resolve({
                config: { data: JSON.stringify({ list: { max_issue_count: 0 } }) },
              }),
            );
            createComponent(
              { activeListId: 1 },
              { updateListWipLimit: spy },
              { edit: true, currentWipLimit: 2 },
            );

            triggerBlur(blurMethod);

            return wrapper.vm.$nextTick().then(() => {
              expect(spy).toHaveBeenCalledTimes(0);
            });
          });
        });

        describe('when response is successful', () => {
          const maxIssueCount = 11;

          beforeEach(() => {
            const spy = jest.fn(() =>
              Promise.resolve({
                config: { data: JSON.stringify({ list: { max_issue_count: maxIssueCount } }) },
              }),
            );
            createComponent({ activeListId: 1 }, { updateListWipLimit: spy }, { edit: true });

            triggerBlur(blurMethod);

            return waitForPromises();
          });

          it('sets activeWipLimit to new maxIssueCount value', () => {
            /*
             * DANGER: bad coupling to the computed prop of the component because the
             * computed prop relys on the list from boardStore, for now this is the way around
             * stale values from boardsStore being updated, when we move List and BoardsStore to Vuex
             * or Graphql we will be able to query the DOM for the new value.
             */
            expect(wrapper.vm.activeList.maxIssueCount).toEqual(maxIssueCount);
          });

          it('toggles GlFormInput on blur', () => {
            expect(wrapper.find(GlFormInput).exists()).toBe(false);
            expect(wrapper.find('.js-wip-limit').exists()).toBe(true);
            expect(wrapper.vm.updating).toBe(false);
          });
        });

        describe('when response fails', () => {
          beforeEach(() => {
            const spy = jest.fn().mockRejectedValue();
            createComponent(
              { activeListId: 1 },
              { updateListWipLimit: spy, setActiveListId: () => {} },
              { edit: true },
            );

            triggerBlur(blurMethod);

            return waitForPromises();
          });

          it('calls flash with expected error', () => {
            expect(flash).toHaveBeenCalledTimes(1);
          });
        });
      });
    });
  });
});
