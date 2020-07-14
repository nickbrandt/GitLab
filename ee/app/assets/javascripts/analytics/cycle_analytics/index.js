import Vue from 'vue';
import CycleAnalytics from './components/base.vue';
import createStore from './store';
import { buildCycleAnalyticsInitialData } from '../shared/utils';
import { parseBoolean } from '~/lib/utils/common_utils';
import { GlToast } from '@gitlab/ui';

Vue.use(GlToast);

export default () => {
  const el = document.querySelector('#js-cycle-analytics-app');
  const { emptyStateSvgPath, noDataSvgPath, noAccessSvgPath, hideGroupDropDown } = el.dataset;
  const initialData = buildCycleAnalyticsInitialData(el.dataset);
  const store = createStore();
  const {
    cycleAnalyticsScatterplotEnabled: hasDurationChart = false,
    cycleAnalyticsScatterplotMedianEnabled: hasDurationChartMedian = false,
    valueStreamAnalyticsPathNavigation: hasPathNavigation = false,
    valueStreamAnalyticsFilterBar: hasFilterBar = false,
    valueStreamAnalyticsCreateMultipleValueStreams: hasCreateMultipleValueStreams = false,
  } = gon?.features;

  store.dispatch('initializeCycleAnalytics', {
    ...initialData,
    featureFlags: {
      hasDurationChart,
      hasDurationChartMedian,
      hasPathNavigation,
      hasFilterBar,
      hasCreateMultipleValueStreams,
    },
  });

  return new Vue({
    el,
    name: 'CycleAnalyticsApp',
    store,
    render: createElement =>
      createElement(CycleAnalytics, {
        props: {
          emptyStateSvgPath,
          noDataSvgPath,
          noAccessSvgPath,
          hideGroupDropDown: parseBoolean(hideGroupDropDown),
        },
      }),
  });
};
