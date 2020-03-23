import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { mockTracking } from 'helpers/tracking_helper';
import createStore from 'ee/subscriptions/new/store';
import Component from 'ee/subscriptions/new/components/checkout.vue';
import ProgressBar from 'ee/subscriptions/new/components/checkout/progress_bar.vue';

describe('Checkout', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let store;
  let wrapper;
  let spy;

  const createComponent = () => {
    wrapper = shallowMount(Component, {
      store,
    });
  };

  const findProgressBar = () => wrapper.find(ProgressBar);

  beforeEach(() => {
    spy = mockTracking('Growth::Acquisition::Experiment::PaidSignUpFlow', null, jest.spyOn);
    store = createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('sends tracking event when snowplow got initialized', () => {
    document.dispatchEvent(new Event('SnowplowInitialized'));

    expect(spy).toHaveBeenCalledWith('Growth::Acquisition::Experiment::PaidSignUpFlow', 'start', {
      label: null,
      property: null,
      value: null,
    });
  });

  describe.each([[true, true], [false, false]])('when isNewUser=%s', (isNewUser, visible) => {
    beforeEach(() => {
      store.state.isNewUser = isNewUser;
    });

    it(`progress bar visibility is ${visible}`, () => {
      expect(findProgressBar().exists()).toBe(visible);
    });
  });
});
