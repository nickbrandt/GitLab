import Vue from 'vue';
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
        },
      });
    },
  });
};
