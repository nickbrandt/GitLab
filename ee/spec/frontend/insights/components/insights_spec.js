import Vue from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import Insights from 'ee/insights/components/insights.vue';
import { createStore } from 'ee/insights/stores';
import createRouter from 'ee/insights/insights_router';
import { pageInfo } from 'ee_jest/insights/mock_data';

describe('Insights component', () => {
  let vm;
  let store;
  let mountComponent;
  const Component = Vue.extend(Insights);
  const router = createRouter('');

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});

    mountComponent = data => {
      const el = null;

      const props = data || {
        endpoint: TEST_HOST,
        queryEndpoint: `${TEST_HOST}/query`,
      };

      return new Component({
        store,
        router,
        propsData: props || {},
      }).$mount(el);
    };

    vm = mountComponent();
  });

  afterEach(() => {
    store.dispatch.mockReset();
    vm.$destroy();
  });

  it('fetches config data when mounted', () => {
    expect(store.dispatch).toHaveBeenCalledWith('insights/fetchConfigData', TEST_HOST);
  });

  describe('when loading config', () => {
    it('renders config loading state', () => {
      vm.$store.state.insights.configLoading = true;

      return vm.$nextTick(() => {
        expect(vm.$el.querySelector('.insights-config-loading')).not.toBe(null);
        expect(vm.$el.querySelector('.insights-wrapper')).toBe(null);
      });
    });
  });

  describe('when config loaded', () => {
    const title = 'Bugs Per Team';
    const page = {
      title,
    };

    beforeEach(() => {
      vm.$store.state.insights.configLoading = false;
      vm.$store.state.insights.activePage = page;
      vm.$store.state.insights.configData = {
        bugsPerTeam: page,
      };
    });

    it('has the correct nav tabs', () => {
      return vm.$nextTick(() => {
        expect(vm.$el.querySelector('.js-insights-dropdown')).not.toBe(null);
        expect(vm.$el.querySelector('.js-insights-dropdown .dropdown-item').innerText.trim()).toBe(
          title,
        );
      });
    });

    describe('when loading page', () => {
      beforeEach(() => {
        vm.$store.state.insights.pageLoading = true;
      });

      it('disables the tab selector', () => {
        return vm.$nextTick(() => {
          expect(
            vm.$el.querySelector('.js-insights-dropdown > button').getAttribute('disabled'),
          ).toBe('disabled');
        });
      });
    });
  });

  describe('empty config', () => {
    beforeEach(() => {
      vm.$store.state.insights.configLoading = false;
      vm.$store.state.insights.configData = null;
    });

    it('it displays a warning', () => {
      return vm.$nextTick(() => {
        expect(vm.$el.querySelector('.js-empty-state').innerText.trim()).toContain(
          'Invalid Insights config file detected',
        );
      });
    });
  });

  describe('filtered out items', () => {
    beforeEach(() => {
      vm.$store.state.insights.configLoading = false;
      vm.$store.state.insights.configData = {};
    });

    it('it displays a warning', () => {
      return vm.$nextTick(() => {
        expect(vm.$el.querySelector('.gl-alert-body').innerText.trim()).toContain(
          'This project is filtered out in the insights.yml file',
        );
      });
    });
  });

  describe('hash fragment present', () => {
    const defaultKey = 'issues';
    const selectedKey = 'mrs';

    const configData = {};
    configData[defaultKey] = {};
    configData[selectedKey] = {};

    beforeEach(() => {
      vm.$store.state.insights.configLoading = false;
      vm.$store.state.insights.configData = configData;
      vm.$store.state.insights.activePage = pageInfo;
    });

    afterEach(() => {
      window.location.hash = '';
    });

    it('selects the first tab if invalid', () => {
      window.location.hash = '#/invalid';

      jest.runOnlyPendingTimers();

      return vm.$nextTick(() => {
        expect(store.dispatch).toHaveBeenCalledWith('insights/setActiveTab', defaultKey);
      });
    });

    it('selects the specified tab if valid', () => {
      window.location.hash = `#/${selectedKey}`;

      jest.runOnlyPendingTimers();

      return vm.$nextTick(() => {
        expect(store.dispatch).toHaveBeenCalledWith('insights/setActiveTab', selectedKey);
      });
    });
  });
});
