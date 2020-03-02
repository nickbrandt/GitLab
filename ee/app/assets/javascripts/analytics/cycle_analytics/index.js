import Vue from 'vue';
import CycleAnalytics from './components/base.vue';
import createStore from './store';
import { buildCycleAnalyticsInitialData } from '../shared/utils';

export default () => {
  const el = document.querySelector('#js-cycle-analytics-app');
  const { emptyStateSvgPath, noDataSvgPath, noAccessSvgPath } = el.dataset;

  const initialData = buildCycleAnalyticsInitialData(el.dataset);
  const store = createStore();
  store.dispatch('initializeCycleAnalytics', initialData);

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
        },
      }),
  });
};
