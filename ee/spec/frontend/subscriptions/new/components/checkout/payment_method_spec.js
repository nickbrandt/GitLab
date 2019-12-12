import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import Step from 'ee/subscriptions/new/components/checkout/components/step.vue';
import Component from 'ee/subscriptions/new/components/checkout/payment_method.vue';

describe('Payment Method', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;

  const store = createStore();

  const createComponent = (opts = {}) => {
    wrapper = mount(Component, {
      localVue,
      sync: false,
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

  describe('validations', () => {
    const isStepValid = () => wrapper.find(Step).props('isValid');

    it('should be valid when paymentMethodId is defined', () => {
      store.commit(types.UPDATE_PAYMENT_METHOD_ID, 'paymentMethodId');

      return localVue.nextTick().then(() => {
        expect(isStepValid()).toBe(true);
      });
    });

    it('should be invalid when paymentMethodId is undefined', () => {
      store.commit(types.UPDATE_PAYMENT_METHOD_ID, null);

      return localVue.nextTick().then(() => {
        expect(isStepValid()).toBe(false);
      });
    });
  });

  describe('showing the summary', () => {
    beforeEach(() => {
      store.commit(types.UPDATE_PAYMENT_METHOD_ID, 'paymentMethodId');
      store.commit(types.UPDATE_CREDIT_CARD_DETAILS, {
        cardType: 'Visa',
        lastFourDigits: '4242',
        expirationMonth: 12,
        expirationYear: 19,
      });
    });

    it('should show the entered credit card details', () => {
      expect(
        wrapper
          .find('.js-summary-line-1')
          .html()
          .replace(/\s+/g, ' '),
      ).toContain('Visa ending in <strong>4242</strong>');
    });

    it('should show the entered credit card expiration date', () => {
      expect(wrapper.find('.js-summary-line-2').text()).toEqual('Exp 12/19');
    });
  });
});
