import { mount } from '@vue/test-utils';
import { createStore } from '~/boards/stores';
import BoardConfigurationOptions from 'ee_component/boards/components/board_configuration_options.vue';

describe('ee_component/boards/components/board_configuration_options.vue', () => {
  let store;
  let wrapper;

  const createWrapper = () => {
    wrapper = mount(BoardConfigurationOptions, {
      store,
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findHideOpenListOption = () => wrapper.find('[data-testid="hide-open-list"]');
  const findHideClosedListOption = () => wrapper.find('[data-testid="hide-closed-list"]');

  describe('when mounted', () => {
    it.each`
      option                | finder
      ${'hide open list'}   | ${findHideOpenListOption}
      ${'hide closed list'} | ${findHideClosedListOption}
    `('renders $option checkbox with default value', ({ finder }) => {
      createWrapper();

      expect(finder().exists()).toBe(true);
      expect(finder().element.checked).toBe(false);
    });

    it.each`
      option                | storeKey            | finder
      ${'hide open list'}   | ${'hideOpenList'}   | ${findHideOpenListOption}
      ${'hide closed list'} | ${'hideClosedList'} | ${findHideClosedListOption}
    `('preloads $option checkbox with stored values', ({ storeKey, finder }) => {
      store.state.configurationOptions = {
        ...store.state.configurationOptions,
        [storeKey]: true,
      };
      createWrapper();

      expect(finder().element.checked).toBe(true);
    });
  });
});
