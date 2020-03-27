import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlDropdownItem } from '@gitlab/ui';
import PanelType from 'ee/monitoring/components/panel_type.vue';
import AlertWidget from 'ee/monitoring/components/alert_widget.vue';
import { graphDataPrometheusQueryRange } from 'jest/monitoring/mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

global.URL.createObjectURL = jest.fn();

describe('Panel Type', () => {
  let wrapper;
  let metricsSavedToDbValue;

  const findAlertsWidget = () => wrapper.find(AlertWidget);
  const findMenuItemAlert = () =>
    wrapper.findAll(GlDropdownItem).filter(i => i.text() === 'Alerts');

  const mockPropsData = {
    graphData: graphDataPrometheusQueryRange,
    clipboardText: 'example_text',
    alertsEndpoint: '/endpoint',
    prometheusAlertsAvailable: true,
  };

  const createWrapper = propsData => {
    const store = new Vuex.Store({
      modules: {
        monitoringDashboard: {
          namespaced: true,
          getters: {
            metricsSavedToDb: jest.fn().mockReturnValue(metricsSavedToDbValue),
          },
        },
      },
    });

    wrapper = shallowMount(PanelType, {
      propsData: {
        ...mockPropsData,
        ...propsData,
      },
      store,
      localVue,
    });
  };

  describe('panel type alerts', () => {
    describe('with license and no metrics in db', () => {
      beforeEach(() => {
        metricsSavedToDbValue = [];
        createWrapper();
        return wrapper.vm.$nextTick();
      });

      it('does not show an alert widget', () => {
        expect(findAlertsWidget().exists()).toBe(false);
      });

      it('does not show menu for alert configuration', () => {
        expect(findMenuItemAlert().exists()).toBe(false);
      });
    });

    describe('with license and related metrics in db', () => {
      beforeEach(() => {
        metricsSavedToDbValue = [graphDataPrometheusQueryRange.metrics[0].metricId];
        createWrapper();
        return wrapper.vm.$nextTick();
      });

      it('shows an alert widget', () => {
        expect(findAlertsWidget().exists()).toBe(true);
      });

      it('shows menu for alert configuration', () => {
        expect(findMenuItemAlert().exists()).toBe(true);
      });
    });

    describe('with license and unrelated metrics in db', () => {
      beforeEach(() => {
        metricsSavedToDbValue = ['another_metric_id'];
        createWrapper();
        return wrapper.vm.$nextTick();
      });

      it('does not show an alert widget', () => {
        expect(findAlertsWidget().exists()).toBe(false);
      });

      it('does not show menu for alert configuration', () => {
        expect(findMenuItemAlert().exists()).toBe(false);
      });
    });

    describe('without license and metrics in db', () => {
      beforeEach(() => {
        metricsSavedToDbValue = [graphDataPrometheusQueryRange.metrics[0].metricId];
        createWrapper({
          prometheusAlertsAvailable: false,
        });
        return wrapper.vm.$nextTick();
      });

      it('does not show an alert widget', () => {
        expect(findAlertsWidget().exists()).toBe(false);
      });

      it('does not show menu for alert configuration', () => {
        expect(findMenuItemAlert().exists()).toBe(false);
      });
    });
  });
});
