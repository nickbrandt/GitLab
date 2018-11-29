import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import Alerts from 'ee/operations/components/dashboard/alerts.vue';
import { removeWhitespace } from 'spec/helpers/vue_component_helper';
import { mockOneProject } from '../../mock_data';

describe('alerts component', () => {
  const AlertsComponent = Vue.extend(Alerts);
  const mockPath = 'https://mock-alert_path/';
  const mount = (props = {}) => mountComponentWithStore(AlertsComponent, { props });
  let vm;

  beforeEach(() => {
    vm = mount();
  });

  afterEach(() => {
    if (vm.$destroy) {
      vm.$destroy();
    }
  });

  it('renders multiple alert count when multiple alerts are present', () => {
    vm = mount({ count: 2 });

    expect(vm.$el.querySelector('.js-alert-count').innerText.trim()).toBe('2 Alerts');
  });

  it('renders count for one alert when there is one alert', () => {
    vm = mount({ count: 1 });

    expect(vm.$el.querySelector('.js-alert-count').innerText.trim()).toBe('1 Alert');
  });

  it('renders last alert when one has fired', () => {
    const mockAlert = mockOneProject.last_alert;
    const alertMessage = `${mockAlert.title} ${mockAlert.operator} ${mockAlert.threshold}`;
    vm = mount({
      count: 1,
      alertPath: mockPath,
      lastAlert: mockAlert,
    });
    const lastAlert = vm.$el.querySelector('.js-last-alert');
    const innerText = removeWhitespace(lastAlert.innerText).trim();

    expect(innerText).toBe(alertMessage);
  });

  it('links last alert to metrics page', () => {
    vm = mount({ alertPath: mockPath });

    expect(vm.$el.querySelector('.js-alert-link').href).toBe(mockPath);
  });

  it('does not render last alert message when it has not fired', () => {
    vm = mount({ alertPath: mockPath });
    const lastAlert = vm.$el.querySelector('.js-last-alert');

    expect(lastAlert.innerText.trim()).toBe('None');
  });

  describe('wrapped components', () => {
    describe('icon', () => {
      it('renders warning', () => {
        expect(vm.$el.querySelector('.ic-warning')).not.toBe(null);
      });
    });
  });
});
