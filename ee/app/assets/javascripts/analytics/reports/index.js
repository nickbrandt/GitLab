import Vue from 'vue';
import ReportsApp from './components/app.vue';

export default () => {
  const el = document.querySelector('#js-reports-app');

  if (!el) return false;

  return new Vue({
    el,
    name: 'ReportsApp',
    render: createElement =>
      createElement(ReportsApp, {
        props: {},
      }),
  });
};
