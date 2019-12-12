import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import { GlLoadingIcon } from '@gitlab/ui';
import Component from 'ee/subscriptions/new/components/checkout/components/zuora.vue';

describe('Zuora', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;

  const store = createStore();

  const createComponent = (opts = {}) => {
    wrapper = shallowMount(Component, {
      localVue,
      sync: false,
      store,
      ...opts,
    });
  };

  const methodMocks = {
    loadZuoraScript: jest.fn(),
    renderZuoraIframe: jest.fn(),
  };

  beforeEach(() => {
    createComponent({ methods: methodMocks, propsData: { active: true } });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('mounted', () => {
    it('should call loadZuoraScript', () => {
      expect(methodMocks.loadZuoraScript).toHaveBeenCalled();
    });
  });

  describe('when active and loading', () => {
    it('the loading indicator should not be shown', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('the zuora_payment selector should be visible', () => {
      expect(wrapper.find('#zuora_payment').element.style.display).toEqual('none');
    });
  });

  describe('when active and not loading', () => {
    beforeEach(() => {
      wrapper.vm.toggleLoading();
    });

    it('the loading indicator should not be shown', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });

    it('the zuora_payment selector should be visible', () => {
      expect(wrapper.find('#zuora_payment').element.style.display).toEqual('');
    });
  });

  describe('not active and not loading', () => {
    beforeEach(() => {
      createComponent({ methods: methodMocks, propsData: { active: false } });
      wrapper.vm.toggleLoading();
    });

    it('the zuora_payment selector should not be visible', () => {
      expect(wrapper.find('#zuora_payment').element.style.display).toEqual('none');
    });
  });

  describe('toggleLoading', () => {
    let spy;

    beforeEach(() => {
      spy = jest.spyOn(wrapper.vm, 'toggleLoading');
    });

    afterEach(() => {
      spy.mockClear();
    });

    it('is called when the paymentMethodId is updated', () => {
      store.commit(types.UPDATE_PAYMENT_METHOD_ID, 'foo');

      return localVue.nextTick().then(() => {
        expect(spy).toHaveBeenCalled();
      });
    });

    it('is called when the creditCardDetails are updated', () => {
      store.commit(types.UPDATE_CREDIT_CARD_DETAILS, {});

      return localVue.nextTick().then(() => {
        expect(spy).toHaveBeenCalled();
      });
    });
  });

  describe('renderZuoraIframe', () => {
    it('is called when the paymentFormParams are updated', () => {
      store.commit(types.UPDATE_PAYMENT_FORM_PARAMS, {});

      return localVue.nextTick().then(() => {
        expect(methodMocks.renderZuoraIframe).toHaveBeenCalled();
      });
    });
  });
});
