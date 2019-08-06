import { shallowMount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { GlModal, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Dashboard from 'ee/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import axios from '~/lib/utils/axios_utils';
import { metricsGroupsAPIResponse, mockApiEndpoint } from 'spec/monitoring/mock_data';
import propsData from 'spec/monitoring/dashboard_spec';
import AlertWidget from 'ee/monitoring/components/alert_widget.vue';
import CustomMetricsFormFields from 'ee/custom_metrics/components/custom_metrics_form_fields.vue';

describe('Dashboard', () => {
  let Component;
  let mock;
  let store;
  let vm;
  const localVue = createLocalVue();

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

  describe('metrics with alert', () => {
    describe('with license', () => {
      beforeEach(() => {
        vm = shallowMount(Component, {
          propsData: {
            ...propsData,
            hasMetrics: true,
            prometheusAlertsAvailable: true,
            alertsEndpoint: '/endpoint',
          },
          store,
        });
      });

      it('shows alert widget and dropdown item', done => {
        setTimeout(() => {
          expect(vm.find(AlertWidget).exists()).toBe(true);
          expect(
            vm
              .findAll(GlDropdownItem)
              .filter(i => i.text() === 'Alerts')
              .exists(),
          ).toBe(true);

          done();
        });
      });

      it('shows More actions dropdown on chart', done => {
        setTimeout(() => {
          expect(
            vm
              .findAll(GlDropdown)
              .filter(d => d.attributes('data-original-title') === 'More actions')
              .exists(),
          ).toBe(true);

          done();
        });
      });
    });

    describe('without license', () => {
      beforeEach(() => {
        vm = shallowMount(Component, {
          propsData: {
            ...propsData,
            hasMetrics: true,
            prometheusAlertsAvailable: false,
            alertsEndpoint: '/endpoint',
          },
          store,
        });
      });

      it('does not show alert widget', done => {
        setTimeout(() => {
          expect(vm.find(AlertWidget).exists()).toBe(false);
          expect(
            vm
              .findAll(GlDropdownItem)
              .filter(i => i.text() === 'Alerts')
              .exists(),
          ).toBe(false);

          done();
        });
      });

      it('hides More actions dropdown on chart', done => {
        setTimeout(() => {
          expect(
            vm
              .findAll(GlDropdown)
              .filter(d => d.attributes('data-original-title') === 'More actions')
              .exists(),
          ).toBe(false);

          done();
        });
      });
    });
  });

  describe('add custom metrics', () => {
    describe('when not available', () => {
      beforeEach(() => {
        vm = shallowMount(Component, {
          propsData: {
            ...propsData,
            customMetricsAvailable: false,
            customMetricsPath: '/endpoint',
            hasMetrics: true,
            prometheusAlertsAvailable: true,
            alertsEndpoint: '/endpoint',
          },
          store,
        });
      });

      it('does not render add button on the dashboard', done => {
        setTimeout(() => {
          expect(vm.element.querySelector('.js-add-metric-button')).toBe(null);
          done();
        });
      });
    });

    describe('when available', () => {
      beforeEach(done => {
        vm = shallowMount(Component, {
          propsData: {
            ...propsData,
            customMetricsAvailable: true,
            customMetricsPath: '/endpoint',
            hasMetrics: true,
            prometheusAlertsAvailable: true,
            alertsEndpoint: '/endpoint',
          },
          store,
        });

        setTimeout(done);
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
