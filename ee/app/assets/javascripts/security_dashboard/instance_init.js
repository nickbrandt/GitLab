import Vue from 'vue';
import projectSelector from './store/plugins/project_selector';
import createStore from './store';
import { DASHBOARD_TYPES } from './store/constants';
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
  const store = createStore({
    dashboardType: DASHBOARD_TYPES.INSTANCE,
    plugins: [projectSelector],
  });

  return new Vue({
    el,
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
