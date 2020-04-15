import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import EERightPane from 'ee/ide/components/panes/right.vue';
import RightPane from '~/ide/components/panes/right.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IDE EERightPane', () => {
  let wrapper;
  let terminalState;

  const factory = () => {
    const store = new Vuex.Store({
      modules: {
        terminal: {
          namespaced: true,
          state: terminalState,
        },
      },
    });

    wrapper = shallowMount(EERightPane, { localVue, store });
  };

  beforeEach(() => {
    terminalState = {};
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('adds terminal tab', () => {
    terminalState.isVisible = true;

    factory();

    expect(wrapper.find(RightPane).props('extensionTabs')).toEqual([
      expect.objectContaining({
        show: true,
        title: 'Terminal',
      }),
    ]);
  });

  it('hides terminal tab when not visible', () => {
    terminalState.isVisible = false;

    factory();

    expect(wrapper.find(RightPane).props('extensionTabs')).toEqual([
      expect.objectContaining({
        show: false,
        title: 'Terminal',
      }),
    ]);
  });
});
