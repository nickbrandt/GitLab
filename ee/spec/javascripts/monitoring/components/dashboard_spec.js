import { shallowMount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import axios from '~/lib/utils/axios_utils';
import { metricsGroupsAPIResponse, mockApiEndpoint } from 'spec/monitoring/mock_data';
import propsData from 'spec/monitoring/dashboard_spec';
import AlertWidget from 'ee/monitoring/components/alert_widget.vue';

describe('Dashboard', () => {
  let Component;
  let mock;
  let vm;
  const localVue = createLocalVue();

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="layout-page"></div>
    `);
    mock = new MockAdapter(axios);
    Component = localVue.extend(Dashboard);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('metrics with alert', () => {
    describe('with license', () => {
      beforeEach(() => {
        mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
        vm = shallowMount(Component, {
          propsData: {
            ...propsData,
            hasMetrics: true,
            prometheusAlertsAvailable: true,
            alertsEndpoint: '/endpoint',
          },
        });
      });

      it('shows alert widget', done => {
        setTimeout(() => {
          expect(vm.find(AlertWidget).exists()).toBe(true);
          done();
        });
      });
    });

    describe('without license', () => {
      beforeEach(() => {
        mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
        vm = shallowMount(Component, {
          propsData: {
            ...propsData,
            hasMetrics: true,
            prometheusAlertsAvailable: false,
            alertsEndpoint: '/endpoint',
          },
        });
      });

      it('does not show alert widget', done => {
        setTimeout(() => {
          expect(vm.find(AlertWidget).exists()).toBe(false);
          done();
        });
      });
    });
  });
});
