import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from 'ee/subscriptions/new/store';
import Component from 'ee/subscriptions/new/components/checkout.vue';
import ProgressBar from 'ee/subscriptions/new/components/checkout/progress_bar.vue';

describe('Checkout', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let store;
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(Component, {
      store,
    });
  };

  const findProgressBar = () => wrapper.find(ProgressBar);

  beforeEach(() => {
    store = createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([[true, true], [false, false]])('when newUser=%s', (newUser, visible) => {
    beforeEach(() => {
      store.state.newUser = newUser;
    });

    it(`progress bar visibility is ${visible}`, () => {
      expect(findProgressBar().exists()).toBe(visible);
    });
  });
});
