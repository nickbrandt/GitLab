import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import Step from 'ee/subscriptions/new/components/checkout/components/step.vue';
import Component from 'ee/subscriptions/new/components/checkout/subscription_details.vue';

describe('Subscription Details', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;

  const planData = [
    { id: 'firstPlanId', code: 'bronze', price_per_year: 48 },
    { id: 'secondPlanId', code: 'silver', price_per_year: 228 },
  ];

  const initialData = {
    planData: JSON.stringify(planData),
    planId: 'secondPlanId',
    setupForCompany: 'true',
    fullName: 'Full Name',
  };

  const store = createStore(initialData);

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

  const isStepValid = () => wrapper.find(Step).props('isValid');

  describe('Setting up for personal use', () => {
    beforeEach(() => {
      store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, false);
      store.commit(types.UPDATE_NUMBER_OF_USERS, 1);
    });

    it('should be valid', () => {
      expect(isStepValid()).toBe(true);
    });

    it('should not display an input field for the company or group name', () => {
      expect(wrapper.find('#organizationName').exists()).toBe(false);
    });

    it('should disable the number of users input field', () => {
      expect(wrapper.find('#numberOfUsers').attributes('disabled')).toBeDefined();
    });

    it('should show a link to change to setting up for a company', () => {
      expect(wrapper.find('.company-link').exists()).toBe(true);
    });
  });

  describe('Setting up for a company or group', () => {
    beforeEach(() => {
      store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, true);
      store.commit(types.UPDATE_NUMBER_OF_USERS, 0);
    });

    it('should be invalid', () => {
      expect(isStepValid()).toBe(false);
    });

    it('should display an input field for the company or group name', () => {
      expect(wrapper.find('#organizationName').exists()).toBe(true);
    });

    it('should enable the number of users input field', () => {
      expect(wrapper.find('#numberOfUsers').attributes('disabled')).toBeUndefined();
    });

    it('should not show the link to change to setting up for a company', () => {
      expect(wrapper.find('.company-link').exists()).toBe(false);
    });

    describe('filling in the company name and the number of users', () => {
      it('should make the component valid', () => {
        store.commit(types.UPDATE_ORGANIZATION_NAME, 'My Organization');
        store.commit(types.UPDATE_NUMBER_OF_USERS, 2);

        return localVue.nextTick().then(() => {
          expect(isStepValid()).toBe(true);
        });
      });
    });
  });

  describe('Showing summary', () => {
    beforeEach(() => {
      store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, true);
      store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
      store.commit(types.UPDATE_ORGANIZATION_NAME, 'My Organization');
      store.commit(types.UPDATE_NUMBER_OF_USERS, 25);
      store.commit(types.UPDATE_CURRENT_STEP, 'nextStep');
    });

    it('should show the selected plan', () => {
      expect(wrapper.find('.js-summary-line-1').text()).toEqual('Bronze plan');
    });

    it('should show the entered group name', () => {
      expect(wrapper.find('.js-summary-line-2').text()).toEqual('Group: My Organization');
    });

    it('should show the entered number of users', () => {
      expect(wrapper.find('.js-summary-line-3').text()).toEqual('Users: 25');
    });
  });
});
