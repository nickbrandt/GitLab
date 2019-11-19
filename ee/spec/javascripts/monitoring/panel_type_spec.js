import { shallowMount, createLocalVue } from '@vue/test-utils';
import { createStore } from '~/monitoring/stores';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import PanelType from 'ee/monitoring/components/panel_type.vue';
import { graphDataPrometheusQueryRange } from 'spec/monitoring/mock_data';
import AlertWidget from 'ee/monitoring/components/alert_widget.vue';

describe('Panel Type', () => {
  let localVue;
  let panelType;
  let store;
  const dashboardWidth = 100;
  const exampleText = 'example_text';

  beforeEach(() => {
    window.gon = {
      ...window.gon,
      ee: true,
    };
  });

  describe('metrics with alert', () => {
    localVue = createLocalVue();

    describe('with license', () => {
      beforeEach(done => {
        store = createStore();

        panelType = shallowMount(PanelType, {
          localVue,
          propsData: {
            clipboardText: exampleText,
            dashboardWidth,
            graphData: graphDataPrometheusQueryRange,
            alertsEndpoint: '/endpoint',
            prometheusAlertsAvailable: true,
          },
          store,
          sync: false,
        });

        panelType.vm.$nextTick(done);
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
      beforeEach(done => {
        store = createStore();

        panelType = shallowMount(PanelType, {
          localVue,
          propsData: {
            clipboardText: exampleText,
            dashboardWidth,
            graphData: graphDataPrometheusQueryRange,
            alertsEndpoint: '/endpoint',
            prometheusAlertsAvailable: false,
          },
          sync: false,
          store,
        });
        panelType.vm.$nextTick(done);
      });

      it('does not show alert widget', done => {
        setTimeout(() => {
          expect(panelType.find(AlertWidget).exists()).toBe(false);
          expect(
            panelType
              .findAll(GlDropdownItem)
              .filter(i => i.text() === 'Alerts')
              .exists(),
          ).toBe(false);

          done();
        });
      });
    });
  });
});
