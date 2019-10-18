import Vue from 'vue';
import createRouter from './store/router';
import projectSelector from './store/plugins/project_selector';
import syncWithRouter from './store/plugins/sync_with_router';
import createStore from './store';
import InstanceSecurityDashboard from './components/instance_security_dashboard.vue';

export default () => {
  const el = document.querySelector('#js-security');
  const {
    dashboardDocumentation,
    emptyStateSvgPath,
    emptyDashboardStateSvgPath,
    projectAddEndpoint,
    projectListEndpoint,
    vulnerabilitiesEndpoint,
    vulnerabilitiesHistoryEndpoint,
    vulnerabilityFeedbackHelpPath,
    vulnerableProjectsEndpoint,
  } = el.dataset;
  const router = createRouter();
  const store = createStore({ plugins: [projectSelector, syncWithRouter(router)] });

  return new Vue({
    el,
    router,
    store,
    render(createElement) {
      return createElement(InstanceSecurityDashboard, {
        props: {
          dashboardDocumentation,
          emptyStateSvgPath,
          emptyDashboardStateSvgPath,
          projectAddEndpoint,
          projectListEndpoint,
          vulnerabilitiesEndpoint,
          vulnerabilitiesHistoryEndpoint,
          vulnerabilityFeedbackHelpPath,
          vulnerableProjectsEndpoint,
        },
      });
    },
  });
};
