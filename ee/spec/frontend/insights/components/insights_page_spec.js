import Vue from 'vue';
import InsightsPage from 'ee/insights/components/insights_page.vue';
import { createStore } from 'ee/insights/stores';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { chartInfo, pageInfo, pageInfoNoCharts } from 'ee_jest/insights/mock_data';

describe('Insights page component', () => {
  let component;
  let store;
  let Component;

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});
    Component = Vue.extend(InsightsPage);
  });

  afterEach(() => {
    component.$destroy();
  });

  describe('no chart config available', () => {
    it('shows an empty state', () => {
      component = mountComponentWithStore(Component, {
        store,
        props: {
          queryEndpoint: `${TEST_HOST}/query`,
          pageConfig: pageInfoNoCharts,
        },
      });

      expect(component.$el.querySelector('.js-empty-state')).not.toBe(null);
    });
  });

  describe('charts configured', () => {
    beforeEach(() => {
      component = mountComponentWithStore(Component, {
        store,
        props: {
          queryEndpoint: `${TEST_HOST}/query`,
          pageConfig: pageInfo,
        },
      });
    });

    it('fetches chart data when mounted', () => {
      expect(store.dispatch).toHaveBeenCalledWith('insights/fetchChartData', {
        endpoint: `${TEST_HOST}/query`,
        chart: chartInfo,
      });
    });

    describe('when charts loading', () => {
      beforeEach(() => {
        component.$store.state.insights.pageLoading = true;
      });

      it('renders loading state', () => {
        return component.$nextTick(() => {
          expect(
            component.$el.querySelector('.js-insights-page-container .insights-chart-loading'),
          ).not.toBe(null);
        });
      });

      it('does display chart area', () => {
        return component.$nextTick(() => {
          expect(
            component.$el.querySelector('.js-insights-page-container .insights-charts'),
          ).not.toBe(null);
        });
      });

      it('does not display chart', () => {
        return component.$nextTick(() => {
          expect(
            component.$el.querySelector(
              '.js-insights-page-container .insights-charts .insights-chart',
            ),
          ).toBe(null);
        });
      });
    });

    describe('pageConfig changes', () => {
      it('reflects new state', () => {
        component.pageConfig = pageInfoNoCharts;

        return component.$nextTick(() => {
          expect(component.$el.querySelector('.js-empty-state')).not.toBe(null);
        });
      });
    });
  });
});
