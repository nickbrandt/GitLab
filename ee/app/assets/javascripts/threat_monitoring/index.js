import Vue from 'vue';
import ThreatMonitoringApp from './components/app.vue';
import createStore from './store';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const el = document.querySelector('#js-threat-monitoring-app');
  const { isWafSetup, endpoint, emptyStateSvgPath, documentationPath } = el.dataset;

  const store = createStore();

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(ThreatMonitoringApp, {
        props: {
          isWafSetup: parseBoolean(isWafSetup),
          endpoint,
          emptyStateSvgPath,
          documentationPath,
        },
      });
    },
  });
};
