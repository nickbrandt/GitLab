import { shallowMount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { GlModal } from '@gitlab/ui';
import Dashboard from 'ee/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import axios from '~/lib/utils/axios_utils';
import {
  metricsGroupsAPIResponse,
  mockApiEndpoint,
  mockedQueryResultPayload,
  environmentData,
} from 'spec/monitoring/mock_data';
import propsData from 'spec/monitoring/components/dashboard_spec';
import CustomMetricsFormFields from 'ee/custom_metrics/components/custom_metrics_form_fields.vue';
import * as types from '~/monitoring/stores/mutation_types';

const localVue = createLocalVue();

describe('Dashboard', () => {
  let Component;
  let mock;
  let store;
  let vm;

  const createComponent = (props = {}) => {
    vm = shallowMount(localVue.extend(Component), {
      propsData: {
        ...propsData,
        ...props,
      },
      store,
      sync: false,
      localVue,
    });
  };

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="layout-page"></div>
    `);

    window.gon = {
      ...window.gon,
      ee: true,
    };

    store = createStore();
    mock = new MockAdapter(axios);
    mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    Component = localVue.extend(Dashboard);
  });

  afterEach(() => {
    mock.restore();
  });

  function setupComponentStore(component) {
    component.vm.$store.commit(
      `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
      metricsGroupsAPIResponse,
    );
    component.vm.$store.commit(
      `monitoringDashboard/${types.SET_QUERY_RESULT}`,
      mockedQueryResultPayload,
    );
    component.vm.$store.commit(
      `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
      environmentData,
    );
  }

  describe('add custom metrics', () => {
    describe('when not available', () => {
      beforeEach(() => {
        createComponent({
          customMetricsAvailable: false,
          customMetricsPath: '/endpoint',
          hasMetrics: true,
          prometheusAlertsAvailable: true,
          alertsEndpoint: '/endpoint',
        });
      });

      it('does not render add button on the dashboard', () => {
        expect(vm.element.querySelector('.js-add-metric-button')).toBe(null);
      });
    });

    describe('when available', () => {
      beforeEach(done => {
        createComponent({
          customMetricsAvailable: true,
          customMetricsPath: '/endpoint',
          hasMetrics: true,
          prometheusAlertsAvailable: true,
          alertsEndpoint: '/endpoint',
        });

        setupComponentStore(vm);

        vm.vm.$nextTick(done);
      });

      it('renders add button on the dashboard', () => {
        expect(vm.element.querySelector('.js-add-metric-button').innerText).toContain('Add metric');
      });

      it('uses modal for custom metrics form', () => {
        expect(vm.find(GlModal).exists()).toBe(true);
        expect(vm.find(GlModal).attributes().modalid).toBe('add-metric');
      });

      it('renders custom metrics form fields', () => {
        expect(vm.find(CustomMetricsFormFields).exists()).toBe(true);
      });
    });
  });
});
