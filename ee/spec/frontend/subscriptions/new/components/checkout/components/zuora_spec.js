import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import { GlLoadingIcon } from '@gitlab/ui';
import Component from 'ee/subscriptions/new/components/checkout/components/zuora.vue';

describe('Zuora', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let store;
  let wrapper;

  const methodMocks = {
    loadZuoraScript: jest.fn(),
    renderZuoraIframe: jest.fn(),
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(Component, {
      propsData: {
        active: true,
        ...props,
      },
      localVue,
      sync: false,
      store,
      methods: methodMocks,
    });
  };

  const findLoading = () => wrapper.find(GlLoadingIcon);
  const findZuoraPayment = () => wrapper.find('#zuora_payment');

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('mounted', () => {
    it('should call loadZuoraScript', () => {
      createComponent();

      expect(methodMocks.loadZuoraScript).toHaveBeenCalled();
    });
  });

  describe('when active', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the loading icon', () => {
      expect(findLoading().exists()).toBe(true);
    });

    it('the zuora_payment selector should not be visible', () => {
      expect(findZuoraPayment().element.style.display).toEqual('none');
    });

    describe.each`
      desc                                    | commitType                          | commitPayload
      ${'when paymentMethodId is updated'}    | ${types.UPDATE_PAYMENT_METHOD_ID}   | ${'foo'}
      ${'when creditCardDetails are updated'} | ${types.UPDATE_CREDIT_CARD_DETAILS} | ${{}}
    `('$desc', ({ commitType, commitPayload }) => {
      beforeEach(() => {
        store.commit(commitType, commitPayload);

        return localVue.nextTick();
      });

      it('does not show loading icon', () => {
        expect(findLoading().exists()).toBe(false);
      });

      it('the zuora_payment selector should be visible', () => {
        expect(findZuoraPayment().element.style.display).toEqual('');
      });
    });
  });

  describe('when not active and not loading', () => {
    beforeEach(() => {
      createComponent({ active: false });

      store.commit(types.UPDATE_PAYMENT_METHOD_ID, 'foo');

      return localVue.nextTick();
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('the zuora_payment selector should not be visible', () => {
      expect(wrapper.find('#zuora_payment').element.style.display).toEqual('none');
    });
  });

  describe('renderZuoraIframe', () => {
    it('is called when the paymentFormParams are updated', () => {
      createComponent();

      expect(methodMocks.renderZuoraIframe).not.toHaveBeenCalled();

      store.commit(types.UPDATE_PAYMENT_FORM_PARAMS, {});

      return localVue.nextTick().then(() => {
        expect(methodMocks.renderZuoraIframe).toHaveBeenCalled();
      });
    });
  });
});
