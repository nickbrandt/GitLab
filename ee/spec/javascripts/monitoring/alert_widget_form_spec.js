import Vue from 'vue';
import AlertWidgetForm from 'ee/monitoring/components/alert_widget_form.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('AlertWidgetForm', () => {
  let AlertWidgetFormComponent;
  let vm;

  const metricId = '8';
  const alertPath = 'alert';
  const relevantQueries = [{ metricId, alert_path: alertPath, label: 'alert-label' }];

  const props = {
    disabled: false,
    relevantQueries,
  };

  const propsWithAlertData = {
    ...props,
    relevantQueries,
    alertsToManage: {
      alert: { alert_path: alertPath, operator: '<', threshold: 5, metricId },
    },
  };

  beforeAll(() => {
    AlertWidgetFormComponent = Vue.extend(AlertWidgetForm);
  });

  afterEach(() => {
    if (vm) vm.$destroy();
  });

  it('disables the input when disabled prop is set', () => {
    vm = mountComponent(AlertWidgetFormComponent, { ...props, disabled: true });

    vm.prometheusMetricId = 6;

    expect(vm.$refs.cancelButton).toBeDisabled();
    expect(vm.$refs.submitButton).toBeDisabled();
  });

  it('disables the input if no query is selected', () => {
    vm = mountComponent(AlertWidgetFormComponent, props);

    expect(vm.$refs.cancelButton).toBeDisabled();
    expect(vm.$refs.submitButton).toBeDisabled();
  });

  it('emits a "create" event when form submitted without existing alert', done => {
    vm = mountComponent(AlertWidgetFormComponent, props);

    expect(vm.$refs.submitButton.innerText).toContain('Add');
    vm.$once('create', alert => {
      expect(alert).toEqual({
        alert: undefined,
        operator: '<',
        threshold: 5,
        prometheus_metric_id: '8',
      });
      done();
    });

    // the button should be disabled until an operator and threshold are selected
    expect(vm.$refs.submitButton).toBeDisabled();
    vm.selectQuery('8');
    vm.operator = '<';
    vm.threshold = 5;
    Vue.nextTick(() => {
      vm.$refs.submitButton.click();
    });
  });

  it('emits a "delete" event when form submitted with existing alert and no changes are made', done => {
    vm = mountComponent(AlertWidgetFormComponent, propsWithAlertData);
    vm.selectQuery('8');

    vm.$once('delete', alert => {
      expect(alert).toEqual({
        alert: 'alert',
        operator: '<',
        threshold: 5,
        prometheus_metric_id: '8',
      });
      done();
    });

    Vue.nextTick(() => {
      expect(vm.$refs.submitButton.innerText).toContain('Delete');
      vm.$refs.submitButton.click();
    });
  });

  it('emits a "update" event when form submitted with existing alert', done => {
    vm = mountComponent(AlertWidgetFormComponent, propsWithAlertData);
    vm.selectQuery('8');
    vm.$once('update', alert => {
      expect(alert).toEqual({
        alert: 'alert',
        operator: '=',
        threshold: 5,
        prometheus_metric_id: '8',
      });
      done();
    });
    Vue.nextTick(() => {
      expect(vm.$refs.submitButton.innerText).toContain('Delete');

      // change operator to allow update
      vm.operator = '=';
      Vue.nextTick(() => {
        expect(vm.$refs.submitButton.innerText).toContain('Save');
        vm.$refs.submitButton.click();
      });
    });
  });
});
