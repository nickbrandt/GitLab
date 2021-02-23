import Vue from 'vue';
import Translate from '../vue_shared/translate';
import CycleAnalytics from './components/base.vue';
import CycleAnalyticsService from './cycle_analytics_service';
import CycleAnalyticsStore from './cycle_analytics_store';

Vue.use(Translate);

const createCycleAnalyticsService = (requestPath) =>
  new CycleAnalyticsService({
    requestPath,
  });

export default () => {
  const cycleAnalyticsEl = document.querySelector('#cycle-analytics');
  const { noAccessSvgPath, noDataSvgPath } = cycleAnalyticsEl.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: '#cycle-analytics',
    name: 'CycleAnalytics',
    render: (createElement) =>
      createElement(CycleAnalytics, {
        props: {
          noDataSvgPath,
          noAccessSvgPath,
          store: CycleAnalyticsStore,
          service: createCycleAnalyticsService(cycleAnalyticsEl.dataset.requestPath),
        },
      }),
  });
};
