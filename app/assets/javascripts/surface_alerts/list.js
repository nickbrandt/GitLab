import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import SurfaceAlertsList from './components/surface_alerts_list.vue';

export default () => {
  const selector = '#js-surface_alerts';

  const domEl = document.querySelector(selector);
  const {
    indexPath,
    enableSurfaceAlertsLink,
    illustrationPath,
  } = domEl.dataset;
  let { surfaceAlertsEnabled } = domEl.dataset;

  surfaceAlertsEnabled = parseBoolean(surfaceAlertsEnabled);

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
          enableSurfaceAlertsLink,
          surfaceAlertsEnabled,
          illustrationPath,
        },
      });
    },
  });
};
