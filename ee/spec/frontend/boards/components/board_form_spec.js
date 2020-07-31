import { shallowMount } from '@vue/test-utils';
import { createStore } from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import BoardForm from '~/boards/components/board_form.vue';
import BoardConfigurationOptions from 'ee_component/boards/components/board_configuration_options.vue';
import { TEST_HOST } from 'jest/helpers/test_constants';

describe('ee_component/boards/components/board_configuration_options.vue', () => {
  let store;
  let wrapper;
  let features = {};

  const createWrapper = () => {
    wrapper = shallowMount(BoardForm, {
      store,
      propsData: {
        canAdminBoard: false,
        labelsPath: `${TEST_HOST}/labels/path`,
        milestonePath: `${TEST_HOST}/milestone/path`,
      },
      provide: { glFeatures: features },
      stubs: {
        'deprecated-modal': '<div><slot name="body"></slot></div>',
      },
    });
  };

  beforeEach(() => {
    boardsStore.state.currentPage = 'edit';
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    features = {};
  });

  const findConfigurationOptions = () => wrapper.find(BoardConfigurationOptions);

  describe('when mounted', () => {
    it('does not render configuration options', () => {
      createWrapper();

      expect(findConfigurationOptions().exists()).toBe(false);
    });

    describe('with `boardConfigurationOptions` feature flag', () => {
      beforeEach(() => {
        features = { boardConfigurationOptions: true };
        createWrapper();
      });

      it('renders configuration options', () => {
        expect(findConfigurationOptions().exists()).toBe(true);
      });
    });
  });
});
