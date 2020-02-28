import Vue from 'vue';
import InsightsPage from 'ee/insights/components/insights_page.vue';
import { createStore } from 'ee/insights/stores';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { chartInfo, pageInfo, pageInfoNoCharts } from '../mock_data';

describe('Insights page component', () => {
  let component;
  let store;
  let Component;

  beforeEach(() => {
    store = createStore();
    spyOn(store, 'dispatch').and.stub();
    Component = Vue.extend(InsightsPage);
  });

  afterEach(() => {
    component.$destroy();
  });

  describe('no chart config available', () => {
    it('shows an empty state', done => {
      component = mountComponentWithStore(Component, {
        store,
        props: {
          queryEndpoint: `${gl.TEST_HOST}/query`,
          pageConfig: pageInfoNoCharts,
        },
      });

      expect(component.$el.querySelector('.js-empty-state')).not.toBe(null);
      done();
    });
  });

  describe('charts configured', () => {
    beforeEach(() => {
      component = mountComponentWithStore(Component, {
        store,
        props: {
          queryEndpoint: `${gl.TEST_HOST}/query`,
          pageConfig: pageInfo,
        },
      });
    });

    it('fetches chart data when mounted', done => {
      expect(store.dispatch).toHaveBeenCalledWith('insights/fetchChartData', {
        endpoint: `${gl.TEST_HOST}/query`,
        chart: chartInfo,
      });
      done();
    });

    describe('when charts loading', () => {
      beforeEach(() => {
        component.$store.state.insights.pageLoading = true;
      });

      it('renders loading state', done => {
        Vue.nextTick(() => {
          expect(
            component.$el.querySelector('.js-insights-page-container .insights-chart-loading'),
          ).not.toBe(null);
          done();
        });
      });

      it('does not display chart area', done => {
        Vue.nextTick(() => {
          expect(component.$el.querySelector('.js-insights-page-container .insights-charts')).toBe(
            null,
          );
          done();
        });
      });
    });

    describe('pageConfig changes', () => {
      it('reflects new state', done => {
        // Establish rendered state
        component.$nextTick();

        component.pageConfig = pageInfoNoCharts;

        component.$nextTick(() => {
          expect(component.$el.querySelector('.js-empty-state')).not.toBe(null);
          done();
        });
      });
    });
  });
});
