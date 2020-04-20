import Vue from 'vue';
import SurfaceAlertsList from './components/surface_alerts_list.vue';

export default () => {
  const selector = '#js-surface_alerts';

  const domEl = document.querySelector(selector);
  const { indexPath, enableSurfaceAlertsPath, emptyAlertSvgPath } = domEl.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    components: {
      SurfaceAlertsList,
    },
    render(createElement) {
      return createElement('surface-alerts-list', {
        props: {
          indexPath,
          enableSurfaceAlertsPath,
          emptyAlertSvgPath,
        },
      });
    },
  });
};
