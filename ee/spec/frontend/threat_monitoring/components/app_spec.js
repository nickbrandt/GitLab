import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { GlAlert } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import createStore from 'ee/threat_monitoring/store';
import ThreatMonitoringApp from 'ee/threat_monitoring/components/app.vue';
import ThreatMonitoringFilters from 'ee/threat_monitoring/components/threat_monitoring_filters.vue';
import WafLoadingSkeleton from 'ee/threat_monitoring/components/waf_loading_skeleton.vue';
import WafStatisticsHistory from 'ee/threat_monitoring/components/waf_statistics_history.vue';
import WafStatisticsSummary from 'ee/threat_monitoring/components/waf_statistics_summary.vue';
import { mockWafStatisticsResponse } from '../mock_data';

const defaultEnvironmentId = 3;
const documentationPath = '/docs';
const chartEmptyStateSvgPath = '/chart-svgs';
const emptyStateSvgPath = '/svgs';
const environmentsEndpoint = `${TEST_HOST}/environments`;
const wafStatisticsEndpoint = `${TEST_HOST}/waf`;
const userCalloutId = 'threat_monitoring_info';
const userCalloutsPath = `${TEST_HOST}/user_callouts`;

describe('ThreatMonitoringApp component', () => {
  let store;
  let wrapper;

  const factory = ({ propsData, state } = {}) => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, {
      environmentsEndpoint,
      wafStatisticsEndpoint,
      ...state,
    });

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(ThreatMonitoringApp, {
      propsData: {
        defaultEnvironmentId,
        chartEmptyStateSvgPath,
        emptyStateSvgPath,
        documentationPath,
        showUserCallout: true,
        userCalloutId,
        userCalloutsPath,
        ...propsData,
      },
      store,
    });
  };

  const findAlert = () => wrapper.find(GlAlert);
  const findFilters = () => wrapper.find(ThreatMonitoringFilters);
  const findWafLoadingSkeleton = () => wrapper.find(WafLoadingSkeleton);
  const findWafStatisticsHistory = () => wrapper.find(WafStatisticsHistory);
  const findWafStatisticsSummary = () => wrapper.find(WafStatisticsSummary);
  const findEmptyState = () => wrapper.find({ ref: 'emptyState' });
  const findChartEmptyState = () => wrapper.find({ ref: 'chartEmptyState' });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([-1, NaN, Math.PI])(
    'given an invalid default environment id of %p',
    invalidEnvironmentId => {
      beforeEach(() => {
        factory({
          propsData: {
            defaultEnvironmentId: invalidEnvironmentId,
          },
        });
      });

      it('dispatches no actions', () => {
        expect(store.dispatch).not.toHaveBeenCalled();
      });

      it('shows only the empty state', () => {
        const emptyState = findEmptyState();
        expect(wrapper.element).toBe(emptyState.element);
        expect(emptyState.props()).toMatchObject({
          svgPath: emptyStateSvgPath,
          primaryButtonLink: documentationPath,
        });
      });
    },
  );

  describe('given there is a default environment with data', () => {
    beforeEach(() => {
      factory({
        state: {
          wafStatistics: mockWafStatisticsResponse,
        },
      });
    });

    it('dispatches the setCurrentEnvironmentId and fetchEnvironments actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        ['threatMonitoring/setCurrentEnvironmentId', defaultEnvironmentId],
        ['threatMonitoring/fetchEnvironments', undefined],
      ]);
    });

    it('shows the alert', () => {
      expect(findAlert().element).toMatchSnapshot();
    });

    it('shows the filter bar', () => {
      expect(findFilters().exists()).toBe(true);
    });

    it('shows the summary and history statistics', () => {
      expect(findWafStatisticsSummary().exists()).toBe(true);
      expect(findWafStatisticsHistory().exists()).toBe(true);
    });

    it('does not show the loading skeleton', () => {
      expect(findWafLoadingSkeleton().exists()).toBe(false);
    });

    describe('dismissing the alert', () => {
      let mockAxios;

      beforeEach(() => {
        mockAxios = new MockAdapter(axios);
        mockAxios.onPost(userCalloutsPath, { feature_name: userCalloutId }).reply(200);

        findAlert().vm.$emit('dismiss');
        return wrapper.vm.$nextTick();
      });

      afterEach(() => {
        mockAxios.restore();
      });

      it('hides the alert', () => {
        expect(findAlert().exists()).toBe(false);
      });

      it('posts the dismissal to the user callouts endpoint', () => {
        expect(mockAxios.history.post).toHaveLength(1);
      });
    });
  });

  describe('given showUserCallout is false', () => {
    beforeEach(() => {
      factory({
        propsData: {
          showUserCallout: false,
        },
      });
    });

    it('does not render the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    describe('given the statistics are loading', () => {
      beforeEach(() => {
        store.state.threatMonitoring.isLoadingWafStatistics = true;
      });

      it('does not show the summary or history statistics', () => {
        expect(findWafStatisticsSummary().exists()).toBe(false);
        expect(findWafStatisticsHistory().exists()).toBe(false);
      });

      it('displays the loading skeleton', () => {
        expect(findWafLoadingSkeleton().exists()).toBe(true);
      });
    });
  });

  describe('given there is a default environment with no data to display', () => {
    beforeEach(() => {
      factory();
    });

    it('shows the filter bar', () => {
      expect(findFilters().exists()).toBe(true);
    });

    it('does not show the summary or history statistics', () => {
      expect(findWafStatisticsSummary().exists()).toBe(false);
      expect(findWafStatisticsHistory().exists()).toBe(false);
    });

    it('shows the chart empty state', () => {
      expect(findChartEmptyState().exists()).toBe(true);
    });
  });
});
