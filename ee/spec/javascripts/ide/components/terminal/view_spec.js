import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { TEST_HOST } from 'spec/test_constants';
import TerminalView from 'ee/ide/components/terminal/view.vue';
import TerminalEmptyState from 'ee/ide/components/terminal/empty_state.vue';

const TEST_SVG_PATH = `${TEST_HOST}/illustration.svg`;

const localVue = createLocalVue();

localVue.use(Vuex);

describe('TerminalView', () => {
  const factory = () => {
    const store = new Vuex.Store({
      state: {
        emptyStateSvgPath: TEST_SVG_PATH,
      },
    });

    return shallowMount(TerminalView, { localVue, store });
  };

  it('renders empty state', () => {
    const wrapper = factory();

    expect(wrapper.find(TerminalEmptyState).props()).toEqual({
      illustrationPath: TEST_SVG_PATH,
    });
  });
});
