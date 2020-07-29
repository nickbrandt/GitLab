import { shallowMount } from '@vue/test-utils';
import { createStore } from '~/monitoring/stores';
import DashboardPage from '~/monitoring/pages/dashboard_page.vue';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { dashboardProps } from '../fixture_data';
import { DASHBOARD_PAGE } from '~/monitoring/router/constants';
import { defaultTimeRange } from '~/vue_shared/constants';
import * as types from '~/monitoring/stores/mutation_types';

const currentDashboard = 'my_dashboard.yml';

const fixedRange = {
  start: '2019-01-01T00:00:00.000Z',
  end: '2019-01-10T00:00:00.000Z',
};

describe('monitoring/pages/dashboard_page', () => {
  let wrapper;
  let store;
  let $router;
  let $route;

  const buildRouter = (route = {}) => {
    $router = {
      push: jest.fn(),
    };
    $route = {
      name: DASHBOARD_PAGE,
      params: { dashboard: currentDashboard },
      query: { dashboard: currentDashboard },
      ...route,
    };
  };

  const createComponent = (props = { dashboardProps }) => {
    wrapper = shallowMount(DashboardPage, {
      store,
      propsData: {
        ...props,
      },
      mocks: {
        $router,
        $route,
      },
    });
  };

  const findDashboardComponent = () => wrapper.find(Dashboard);

  beforeEach(() => {
    buildRouter();
    store = createStore();
    jest.spyOn(store, 'dispatch').mockResolvedValue();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  it('throws errors if dashboard props are not passed', () => {
    expect(() => createComponent({})).toThrow('Missing required prop: "dashboardProps"');
  });

  it('renders the dashboard page with dashboard component', () => {
    createComponent();

    const allProps = {
      ...dashboardProps,
      // default props values
      rearrangePanelsAvailable: false,
      showHeader: true,
      showPanels: true,
      smallEmptyState: false,
    };

    expect(findDashboardComponent()).toExist();
    expect(allProps).toMatchObject(findDashboardComponent().props());
  });

  it('sets the current dashboard', () => {
    createComponent();

    expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setCurrentDashboard', {
      currentDashboard,
    });
  });

  it('sets the default time range', () => {
    createComponent();

    expect(store.dispatch).toHaveBeenCalledWith(
      'monitoringDashboard/setTimeRange',
      defaultTimeRange,
    );
  });

  it('sets a fixed time range from URL query', () => {
    buildRouter({ query: fixedRange });
    createComponent();

    expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setTimeRange', fixedRange);
  });

  it('set a rolling time range from URL query', () => {
    buildRouter({ query: { duration_seconds: '120' } });
    createComponent();

    expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setTimeRange', {
      duration: {
        seconds: 120,
      },
    });
  });

  it('updates the URL query when the time range changes', () => {
    createComponent();

    expect($router.push).not.toHaveBeenCalled();

    store.commit(`monitoringDashboard/${types.SET_TIME_RANGE}`, fixedRange);

    return wrapper.vm.$nextTick().then(() => {
      expect($router.push).toHaveBeenCalledWith(
        expect.objectContaining({
          query: {
            start: fixedRange.start,
            end: fixedRange.end,
            dashboard: currentDashboard,
          },
        }),
      );
    });
  });
});
