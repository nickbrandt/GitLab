import { shallowMount, createLocalVue } from '@vue/test-utils';
import { TEST_HOST } from 'spec/test_constants';
import TerminalEmptyState from 'ee/ide/components/terminal/empty_state.vue';

const TEST_PATH = `${TEST_HOST}/home.png`;

describe('TerminalEmptyState', () => {
  const factory = (options = {}) => {
    const localVue = createLocalVue();

    return shallowMount(TerminalEmptyState, {
      localVue,
      ...options,
    });
  };

  it('does not show illustration, if no path specified', () => {
    const wrapper = factory();

    expect(wrapper.find('.svg-content').exists()).toBe(false);
  });

  it('shows illustration with path', () => {
    const wrapper = factory({
      propsData: {
        illustrationPath: TEST_PATH,
      },
    });

    const img = wrapper.find('.svg-content img');

    expect(img.exists()).toBe(true);
    expect(img.attributes('src')).toEqual(TEST_PATH);
  });
});
