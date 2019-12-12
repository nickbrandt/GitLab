import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import createStore from 'ee/threat_monitoring/store';
import ThreatMonitoringApp from 'ee/threat_monitoring/components/app.vue';

const localVue = createLocalVue();
const endpoint = TEST_HOST;
const emptyStateSvgPath = '/svgs';
const documentationPath = '/docs';

describe('ThreatMonitoringApp component', () => {
  let store;
  let wrapper;

  const factory = propsData => {
    store = createStore();

    jest.spyOn(store, 'dispatch');

    wrapper = shallowMount(ThreatMonitoringApp, {
      localVue,
      propsData,
      store,
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('given the WAF is not set up', () => {
    beforeEach(() => {
      factory({
        isWafSetup: false,
        endpoint,
        emptyStateSvgPath,
        documentationPath,
      });
    });

    it('does not dispatch any store actions', () => {
      expect(store.dispatch).not.toHaveBeenCalled();
    });

    it('shows only the empty state', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('given the WAF is set up', () => {
    beforeEach(() => {
      factory({
        isWafSetup: true,
        endpoint,
        emptyStateSvgPath,
        documentationPath,
      });
    });

    it('sets the endpoint on creation', () => {
      expect(store.dispatch).toHaveBeenCalledWith('threatMonitoring/setEndpoint', endpoint);
    });

    it('shows the alert and header', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('dismissing the alert', () => {
      beforeEach(() => {
        wrapper.find(GlAlert).vm.$emit('dismiss');
      });

      it('hides the alert', () => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });
  });
});
