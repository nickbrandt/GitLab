import Vue from 'vue';
import AlertWidget from 'ee/monitoring/components/alert_widget.vue';
import AlertsService from 'ee/monitoring/services/alerts_service';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import waitForPromises from 'spec/helpers/wait_for_promises';

describe('AlertWidget', () => {
  let AlertWidgetComponent;
  let vm;

  const metricId = '5';
  const alertPath = 'my/alert.json';
  const relevantQueries = [{ metricId, label: 'alert-label', alert_path: alertPath }];

  const props = {
    alertsEndpoint: '',
    relevantQueries,
    alertsToManage: {},
    modalId: 'alert-modal-1',
  };

  const propsWithAlert = {
    ...props,
    relevantQueries,
  };

  const propsWithAlertData = {
    ...props,
    relevantQueries,
    alertsToManage: {
      [alertPath]: { operator: '>', threshold: 42, alert_path: alertPath, metricId },
    },
  };

  const mockSetAlerts = (path, data) => {
    const alerts = data ? { [path]: data } : {};
    Vue.set(vm, 'alertsToManage', alerts);
  };

  beforeAll(() => {
    AlertWidgetComponent = Vue.extend(AlertWidget);
  });

  beforeEach(() => {
    setFixtures('<div id="alert-widget"></div>');
  });

  afterEach(() => {
    if (vm) vm.$destroy();
  });

  it('displays a loading spinner when fetching alerts', done => {
    let resolveReadAlert;

    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(
      new Promise(cb => {
        resolveReadAlert = cb;
      }),
    );
    vm = mountComponent(AlertWidgetComponent, propsWithAlert, '#alert-widget');

    // expect loading spinner to exist during fetch
    expect(vm.isLoading).toBeTruthy();
    expect(vm.$el.querySelector('.loading-container')).toBeVisible();

    resolveReadAlert({ operator: '=', threshold: 42 });

    // expect loading spinner to go away after fetch
    setTimeout(() =>
      vm.$nextTick(() => {
        expect(vm.isLoading).toEqual(false);
        expect(vm.$el.querySelector('.loading-container')).toBeHidden();
        done();
      }),
    );
  });

  it('displays an error message when fetch fails', done => {
    const spy = spyOnDependency(AlertWidget, 'createFlash');
    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(Promise.reject());
    vm = mountComponent(AlertWidgetComponent, propsWithAlert, '#alert-widget');

    setTimeout(() =>
      vm.$nextTick(() => {
        expect(vm.isLoading).toEqual(false);
        expect(spy).toHaveBeenCalled();
        done();
      }),
    );
  });

  it('displays an alert summary when there is a single alert', () => {
    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(
      Promise.resolve({ operator: '>', threshold: 42 }),
    );
    vm = mountComponent(AlertWidgetComponent, propsWithAlertData, '#alert-widget');

    expect(vm.alertSummary).toBe('alert-label > 42');
    expect(vm.$el.querySelector('.alert-current-setting')).toBeVisible();
  });

  it('displays a combined alert summary when there are multiple alerts', () => {
    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(
      Promise.resolve({ operator: '>', threshold: 42 }),
    );
    const propsWithManyAlerts = {
      ...props,
      relevantQueries: relevantQueries.concat([
        { metricId: '6', alert_path: 'my/alert2.json', label: 'alert-label2' },
      ]),
      alertsToManage: {
        'my/alert.json': {
          operator: '>',
          threshold: 42,
          alert_path: alertPath,
          metricId,
        },
        'my/alert2.json': {
          operator: '=',
          threshold: 900,
          alert_path: 'my/alert2.json',
          metricId: '6',
        },
      },
    };
    vm = mountComponent(AlertWidgetComponent, propsWithManyAlerts, '#alert-widget');

    expect(vm.alertSummary).toBe('alert-label > 42, alert-label2 = 900');
    expect(vm.$el.querySelector('.alert-current-setting')).toBeVisible();
  });

  it('creates an alert with an appropriate handler', done => {
    const alertParams = {
      operator: '<',
      threshold: 4,
      prometheus_metric_id: '5',
    };

    spyOn(AlertsService.prototype, 'createAlert').and.returnValue(
      Promise.resolve({ alert_path: 'foo/bar', ...alertParams }),
    );

    vm = mountComponent(AlertWidgetComponent, props);
    vm.$on('setAlerts', mockSetAlerts);

    vm.$refs.widgetForm.$emit('create', alertParams);

    expect(AlertsService.prototype.createAlert).toHaveBeenCalledWith(alertParams);

    waitForPromises()
      .then(() => {
        expect(vm.isLoading).toEqual(false);
        done();
      })
      .catch(done.fail);
  });

  it('updates an alert with an appropriate handler', done => {
    const alertParams = { operator: '<', threshold: 4, alert_path: alertPath };
    const newAlertParams = { operator: '=', threshold: 12 };

    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(Promise.resolve(alertParams));
    spyOn(AlertsService.prototype, 'updateAlert').and.returnValue(
      Promise.resolve({ ...alertParams, ...newAlertParams }),
    );

    vm = mountComponent(AlertWidgetComponent, propsWithAlertData);
    vm.$on('setAlerts', mockSetAlerts);

    vm.$refs.widgetForm.$emit('update', {
      alert: alertPath,
      ...newAlertParams,
      prometheus_metric_id: '5',
    });

    expect(AlertsService.prototype.updateAlert).toHaveBeenCalledWith(alertPath, newAlertParams);
    waitForPromises()
      .then(() => {
        expect(vm.isLoading).toEqual(false);
        done();
      })
      .catch(done.fail);
  });

  it('deletes an alert with an appropriate handler', done => {
    const alertParams = { alert_path: alertPath, operator: '>', threshold: 42 };

    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(Promise.resolve(alertParams));
    spyOn(AlertsService.prototype, 'deleteAlert').and.returnValue(Promise.resolve({}));

    vm = mountComponent(AlertWidgetComponent, propsWithAlert);
    vm.$on('setAlerts', mockSetAlerts);

    vm.$refs.widgetForm.$emit('delete', { alert: alertPath });

    expect(AlertsService.prototype.deleteAlert).toHaveBeenCalledWith(alertPath);
    waitForPromises()
      .then(() => {
        expect(vm.isLoading).toEqual(false);
        expect(vm.alertSummary).toBeFalsy();
        done();
      })
      .catch(done.fail);
  });
});
