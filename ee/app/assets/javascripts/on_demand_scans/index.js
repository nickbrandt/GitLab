import Vue from 'vue';
import OnDemandScansApp from './components/on_demand_scans_app.vue';

export default () => {
  const el = document.querySelector('#js-on-demand-scans-app');
  if (!el) {
    return;
  }

  const { helpPagePath, emptyStateSvgPath } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(h) {
      return h(OnDemandScansApp, {
        props: {
          helpPagePath,
          emptyStateSvgPath,
        },
      });
    },
  });
};
