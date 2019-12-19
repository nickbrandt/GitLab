import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ThreatMonitoringApp from './components/app.vue';
import createStore from './store';

export default () => {
  const el = document.querySelector('#js-threat-monitoring-app');
  const {
    wafStatisticsEndpoint,
    environmentsEndpoint,
    emptyStateSvgPath,
    documentationPath,
    defaultEnvironmentId,
    showUserCallout,
    userCalloutId,
    userCalloutsPath,
  } = el.dataset;

  const store = createStore();
  store.dispatch('threatMonitoring/setEndpoints', {
    wafStatisticsEndpoint,
    environmentsEndpoint,
  });

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(ThreatMonitoringApp, {
        props: {
          emptyStateSvgPath,
          documentationPath,
          defaultEnvironmentId: parseInt(defaultEnvironmentId, 10),
          showUserCallout: parseBoolean(showUserCallout),
          userCalloutId,
          userCalloutsPath,
        },
      });
    },
  });
};
