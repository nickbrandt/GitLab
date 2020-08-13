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
    const chart1 = { title: 'foo' };
    const chart2 = { title: 'bar' };

    describe('when charts have not been initialized', () => {
      const page = {
        title,
        charts: [],
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
          expect(
            vm.$el.querySelector('.js-insights-dropdown .dropdown-item').innerText.trim(),
          ).toBe(title);
        });
      });

      it('disables the tab selector', () => {
        return vm.$nextTick(() => {
          expect(
            vm.$el.querySelector('.js-insights-dropdown > button').getAttribute('disabled'),
          ).toBe('disabled');
        });
      });
    });

    describe('when charts have been initialized', () => {
      const page = {
        title,
        charts: [chart1, chart2],
      };

      beforeEach(() => {
        vm.$store.state.insights.configLoading = false;
        vm.$store.state.insights.activePage = page;
        vm.$store.state.insights.configData = {
          bugsPerTeam: page,
        };
        vm.$store.state.insights.chartData = {
          [chart1.title]: {},
          [chart2.title]: {},
        };
      });

      it('enables the tab selector', () => {
        return vm.$nextTick(() => {
          expect(
            vm.$el.querySelector('.js-insights-dropdown > button').getAttribute('disabled'),
          ).toBe('disabled');
        });
      });
    });

    describe('when some charts have been loaded', () => {
      const page = {
        title,
        charts: [chart1],
      };

      beforeEach(() => {
        vm.$store.state.insights.configLoading = false;
        vm.$store.state.insights.activePage = page;
        vm.$store.state.insights.configData = {
          bugsPerTeam: page,
        };
        vm.$store.state.insights.chartData = {
          [chart2.title]: { loaded: true },
        };
      });

      it('disables the tab selector', () => {
        return vm.$nextTick(() => {
          expect(
            vm.$el.querySelector('.js-insights-dropdown > button').getAttribute('disabled'),
          ).toBe('disabled');
        });
      });
    });

    describe('when all charts have loaded', () => {
      const page = {
        title,
        charts: [chart1, chart2],
      };

      beforeEach(() => {
        vm.$store.state.insights.configLoading = false;
        vm.$store.state.insights.activePage = page;
        vm.$store.state.insights.configData = {
          bugsPerTeam: page,
        };
        vm.$store.state.insights.chartData = {
          [chart1.title]: { loaded: true },
          [chart2.title]: { loaded: true },
        };
      });

      it('enables the tab selector', () => {
        return vm.$nextTick(() => {
          expect(
            vm.$el.querySelector('.js-insights-dropdown > button').getAttribute('disabled'),
          ).toBe(null);
        });
      });
    });

    describe('when one chart has an error', () => {
      const page = {
        title,
        charts: [chart1, chart2],
      };

      beforeEach(() => {
        vm.$store.state.insights.configLoading = false;
        vm.$store.state.insights.activePage = page;
        vm.$store.state.insights.configData = {
          bugsPerTeam: page,
        };
        vm.$store.state.insights.chartData = {
          [chart1.title]: { error: 'Baz' },
          [chart2.title]: { loaded: true },
        };
      });

      it('enables the tab selector', () => {
        return vm.$nextTick(() => {
          expect(
            vm.$el.querySelector('.js-insights-dropdown > button').getAttribute('disabled'),
          ).toBe(null);
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

    it('does not display dropdown', () => {
      return vm.$nextTick(() => {
        expect(vm.$el.querySelector('.js-insights-dropdown > button')).toBe(null);
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

    it('does not display dropdown', () => {
      return vm.$nextTick(() => {
        expect(vm.$el.querySelector('.js-insights-dropdown > button')).toBe(null);
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
