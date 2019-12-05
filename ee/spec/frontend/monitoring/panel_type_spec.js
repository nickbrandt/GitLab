import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { createStore } from '~/monitoring/stores';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import PanelType from 'ee/monitoring/components/panel_type.vue';
import AlertWidget from 'ee/monitoring/components/alert_widget.vue';
import { graphDataPrometheusQueryRange } from '../../../../spec/frontend/monitoring/mock_data';

global.URL.createObjectURL = jest.fn();

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Panel Type', () => {
  let axiosMock;
  let panelType;
  let store;
  const dashboardWidth = 100;
  const exampleText = 'example_text';

  const createWrapper = propsData => {
    store = createStore();
    panelType = shallowMount(PanelType, {
      propsData,
      store,
      localVue,
      sync: false,
      attachToDocument: true,
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    window.gon = {
      ...window.gon,
      ee: true,
    };
  });

  afterEach(() => {
    axiosMock.reset();
  });

  describe('metrics with alert', () => {
    describe('with license', () => {
      beforeEach(() => {
        createWrapper({
          clipboardText: exampleText,
          dashboardWidth,
          graphData: graphDataPrometheusQueryRange,
          alertsEndpoint: '/endpoint',
          prometheusAlertsAvailable: true,
        });
      });

      afterEach(() => {
        panelType.destroy();
      });

      it('shows alert widget and dropdown item', done => {
        localVue.nextTick(() => {
          expect(panelType.find(AlertWidget).exists()).toBe(true);
          expect(
            panelType
              .findAll(GlDropdownItem)
              .filter(i => i.text() === 'Alerts')
              .exists(),
          ).toBe(true);

          done();
        });
      });

      it('shows More actions dropdown on chart', done => {
        localVue.nextTick(() => {
          expect(
            panelType
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
        createWrapper({
          clipboardText: exampleText,
          dashboardWidth,
          graphData: graphDataPrometheusQueryRange,
          alertsEndpoint: '/endpoint',
          prometheusAlertsAvailable: false,
        });
      });

      it('does not show alert widget', () => {
        expect(panelType.find(AlertWidget).exists()).toBe(false);
        expect(
          panelType
            .findAll(GlDropdownItem)
            .filter(i => i.text() === 'Alerts')
            .exists(),
        ).toBe(false);
      });
    });
  });
});
