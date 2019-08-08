import Vue from 'vue';
import CycleAnalytics from './components/base.vue';

export default () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-cycle-analytics-app',
    name: 'CycleAnalyticsApp',
    components: {
      CycleAnalytics,
    },
    render: createElement => createElement('cycle-analytics', {}),
  });
};
