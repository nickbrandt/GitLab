import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import { GlButton } from '@gitlab/ui';
import Component from 'ee/subscriptions/new/components/checkout/confirm_order.vue';

describe('Confirm Order', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;

  const store = createStore();

  const createComponent = (opts = {}) => {
    wrapper = shallowMount(Component, {
      localVue,
      store,
      ...opts,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Active', () => {
    beforeEach(() => {
      store.commit(types.UPDATE_CURRENT_STEP, 'confirmOrder');
    });

    it('button should be visible', () => {
      expect(wrapper.find(GlButton).exists()).toBe(true);
    });
  });

  describe('Inactive', () => {
    beforeEach(() => {
      store.commit(types.UPDATE_CURRENT_STEP, 'otherStep');
    });

    it('button should not be visible', () => {
      expect(wrapper.find(GlButton).exists()).toBe(false);
    });
  });
});
