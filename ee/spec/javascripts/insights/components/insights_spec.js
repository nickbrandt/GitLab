import Vue from 'vue';
import Insights from 'ee/insights/components/insights.vue';
import { createStore } from 'ee/insights/stores';
import createRouter from 'ee/insights/insights_router';
import { pageInfo } from '../mock_data';

describe('Insights component', () => {
  let vm;
  let store;
  let mountComponent;
  const Component = Vue.extend(Insights);
  const router = createRouter('');

  beforeEach(() => {
    store = createStore();
    spyOn(store, 'dispatch').and.stub();

    mountComponent = data => {
      const el = null;

      const props = data || {
        endpoint: gl.TEST_HOST,
        queryEndpoint: `${gl.TEST_HOST}/query`,
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
    vm.$destroy();
  });

  it('fetches config data when mounted', done => {
    expect(store.dispatch).toHaveBeenCalledWith('insights/fetchConfigData', gl.TEST_HOST);
    done();
  });

  describe('when loading config', () => {
    it('renders config loading state', done => {
      vm.$store.state.insights.configLoading = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.insights-config-loading')).not.toBe(null);
        expect(vm.$el.querySelector('.insights-wrapper')).toBe(null);
        done();
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

    it('has the correct nav tabs', done => {
      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.js-insights-dropdown')).not.toBe(null);
        expect(vm.$el.querySelector('.js-insights-dropdown .dropdown-item').innerText.trim()).toBe(
          title,
        );
        done();
      });
    });

    describe('when loading page', () => {
      beforeEach(() => {
        vm.$store.state.insights.pageLoading = true;
      });

      it('disables the tab selector', done => {
        vm.$nextTick(() => {
          expect(
            vm.$el.querySelector('.js-insights-dropdown > button').getAttribute('disabled'),
          ).toBe('disabled');
          done();
        });
      });
    });
  });

  describe('empty config', () => {
    beforeEach(() => {
      vm.$store.state.insights.configLoading = false;
      vm.$store.state.insights.configData = null;
    });

    it('it displays a warning', done => {
      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.js-empty-state').innerText.trim()).toContain(
          'Invalid Insights config file detected',
        );
        done();
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

    it('selects the first tab if invalid', done => {
      window.location.hash = '#/invalid';

      vm.$nextTick(() => {
        expect(store.dispatch).toHaveBeenCalledWith('insights/setActiveTab', defaultKey);
      });
      done();
    });

    it('selects the specified tab if valid', done => {
      window.location.hash = `#/${selectedKey}`;

      vm.$nextTick(() => {
        expect(store.dispatch).toHaveBeenCalledWith('insights/setActiveTab', selectedKey);
      });
      done();
    });
  });
});
