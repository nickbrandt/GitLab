import Vue from 'vue';
import GroupSecurityDashboardApp from './components/app.vue';
import createStore from './store';
import router from './store/router';

export default () => {
  const el = document.getElementById('js-group-security-dashboard');

  const store = createStore();

  return new Vue({
    el,
    store,
    router,
    components: {
      GroupSecurityDashboardApp,
    },
    render(createElement) {
      return createElement('group-security-dashboard-app', {
        props: {
          dashboardDocumentation: el.dataset.dashboardDocumentation,
          emptyStateSvgPath: el.dataset.emptyStateSvgPath,
          projectsEndpoint: el.dataset.projectsEndpoint,
          vulnerabilityFeedbackHelpPath: el.dataset.vulnerabilityFeedbackHelpPath,
          vulnerabilitiesEndpoint: el.dataset.vulnerabilitiesEndpoint,
          vulnerabilitiesCountEndpoint: el.dataset.vulnerabilitiesSummaryEndpoint,
          vulnerabilitiesHistoryEndpoint: el.dataset.vulnerabilitiesHistoryEndpoint,
        },
      });
    },
  });
};
