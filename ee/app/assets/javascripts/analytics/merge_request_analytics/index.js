import Vue from 'vue';
import MergeRequestAnalyticsApp from './components/app.vue';

export default () => {
  const el = document.querySelector('#js-merge-request-analytics-app');

  if (!el) return false;

  return new Vue({
    el,
    name: 'MergeRequestAnalyticsApp',
    render: createElement => createElement(MergeRequestAnalyticsApp),
  });
};
