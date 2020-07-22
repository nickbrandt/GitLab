import { mount, createLocalVue } from '@vue/test-utils';
import VueRouter from 'vue-router';
import DashboardPage from '~/monitoring/pages/dashboard_page.vue';
import PanelNewPage from '~/monitoring/pages/panel_new_page.vue';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import createRouter from '~/monitoring/router';
import { dashboardProps } from './fixture_data';
import { dashboardHeaderProps } from './mock_data';

const LEGACY_BASE_PATH = '/project/my-group/test-project/-/environments/71146/metrics';
const BASE_PATH = '/project/my-group/test-project/-/metrics';

const MockApp = {
  data() {
    return {
      dashboardProps: { ...dashboardProps, ...dashboardHeaderProps },
    };
  },
  template: `<router-view  :dashboard-props="dashboardProps"/>`,
};

describe('Monitoring router', () => {
  let router;
  let store;

  const createWrapper = (basePath, routeArg) => {
    const localVue = createLocalVue();
    localVue.use(VueRouter);

    router = createRouter(basePath);
    if (routeArg !== undefined) {
      router.push(routeArg);
    }

    return mount(MockApp, {
      localVue,
      store,
      router,
    });
  };

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockResolvedValue();
  });

  afterEach(() => {
    window.location.hash = '';
  });

  describe('support legacy URL with full dashboard path to visit dashboard page', () => {
    it.each`
      route                          | currentDashboard
      ${'/dashboard.yml'}            | ${'dashboard.yml'}
      ${'/folder1/dashboard.yml'}    | ${'folder1/dashboard.yml'}
      ${'/?dashboard=dashboard.yml'} | ${'dashboard.yml'}
    `('sets component as $componentName for path "$route"', ({ route, currentDashboard }) => {
      const wrapper = createWrapper(LEGACY_BASE_PATH, route);

      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setCurrentDashboard', {
        currentDashboard,
      });

      expect(wrapper.find(DashboardPage).exists()).toBe(true);
      expect(
        wrapper
          .find(DashboardPage)
          .find(Dashboard)
          .exists(),
      ).toBe(true);
    });
  });

  describe('supports URL to visit dashboard page', () => {
    it.each`
      route                                       | currentDashboard
      ${'/'}                                      | ${null}
      ${'/dashboard.yml'}                         | ${'dashboard.yml'}
      ${'/folder1/dashboard.yml'}                 | ${'folder1/dashboard.yml'}
      ${'/folder1%2Fdashboard.yml'}               | ${'folder1/dashboard.yml'}
      ${'/dashboard.yml'}                         | ${'dashboard.yml'}
      ${'/config/prometheus/common_metrics.yml'}  | ${'config/prometheus/common_metrics.yml'}
      ${'/config/prometheus/pod_metrics.yml'}     | ${'config/prometheus/pod_metrics.yml'}
      ${'/config%2Fprometheus%2Fpod_metrics.yml'} | ${'config/prometheus/pod_metrics.yml'}
    `('sets component as $componentName for path "$route"', ({ route, currentDashboard }) => {
      const wrapper = createWrapper(BASE_PATH, route);

      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setCurrentDashboard', {
        currentDashboard,
      });

      expect(wrapper.find(DashboardPage).exists()).toBe(true);
      expect(
        wrapper
          .find(DashboardPage)
          .find(Dashboard)
          .exists(),
      ).toBe(true);
    });
  });

  describe('supports URL to visit new panel page', () => {
    it.each`
      route                                                    | currentDashboard
      ${'/panel/new'}                                          | ${undefined}
      ${'/dashboard.yml/panel/new'}                            | ${'dashboard.yml'}
      ${'/config/prometheus/common_metrics.yml/panel/new'}     | ${'config/prometheus/common_metrics.yml'}
      ${'/config%2Fprometheus%2Fcommon_metrics.yml/panel/new'} | ${'config/prometheus/common_metrics.yml'}
    `(
      'displays the new panel page for path "$route" with route param $currentDashboard',
      ({ route, currentDashboard }) => {
        const wrapper = createWrapper(BASE_PATH, route);

        expect(wrapper.vm.$route.params.dashboard).toBe(currentDashboard);
        expect(wrapper.find(PanelNewPage).exists()).toBe(true);
      },
    );
  });
});
