import Vue from 'vue';
import CycleAnalytics from './components/base.vue';
import createStore from './store';

export default () => {
  const el = document.querySelector('#js-cycle-analytics-app');
  const { emptyStateSvgPath, noDataSvgPath, noAccessSvgPath } = el.dataset;

  return new Vue({
    el,
    name: 'CycleAnalyticsApp',
    store: createStore(),
    components: {
      CycleAnalytics,
    },
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
