import Vue from 'vue';
import component from 'ee/billings/components/subscription_table.vue';
import createStore from 'ee/billings/stores';
import * as types from 'ee/billings/stores/modules/subscription/mutation_types';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import mockDataSubscription from '../mock_data';
import { resetStore } from '../helpers';

describe('Subscription Table', () => {
  const Component = Vue.extend(component);
  let store;
  let vm;

  beforeEach(() => {
    store = createStore();
    vm = createComponentWithStore(Component, store, {});
    spyOn(vm.$store, 'dispatch');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(store);
  });

  it('renders loading icon', done => {
    vm.$store.state.subscription.isLoading = true;

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.loading-container')).not.toBe(null);
      })
      .then(done)
      .catch(done.fail);
  });

  describe('with success', () => {
    const namespaceId = 1;

    beforeEach(done => {
      vm.$store.state.subscription.namespaceId = namespaceId;
      vm.$store.commit(
        `subscription/${types.RECEIVE_SUBSCRIPTION_SUCCESS}`,
        mockDataSubscription.gold,
      );
      vm.$store.state.subscription.isLoading = false;
      vm.$nextTick(done);
    });

    it('should render the card title "GitLab.com Gold"', () => {
      expect(vm.$el.querySelector('.js-subscription-header strong').textContent.trim()).toBe(
        'GitLab.com Gold',
      );
    });

    it('should render a link labelled "Manage" in the card header', () => {
      expect(vm.$el.querySelector('.js-subscription-header .btn').textContent.trim()).toBe(
        'Manage',
      );
    });

    it('should render a link linking to the customer portal', () => {
      expect(vm.$el.querySelector('.js-subscription-header .btn').getAttribute('href')).toBe(
        'https://customers.gitlab.com/subscriptions',
      );
    });

    it('should render a "Usage" and a "Billing" row', () => {
      expect(vm.$el.querySelectorAll('.grid-row')).toHaveLength(2);
    });
  });
});
