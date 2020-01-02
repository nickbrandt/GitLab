import Vue from 'vue';
import GroupSecurityDashboardApp from './components/group_security_dashboard.vue';
import UnavailableState from './components/unavailable_state.vue';
import createStore from './store';
import createRouter from './store/router';
import projectsPlugin from './store/plugins/projects';
import syncWithRouter from './store/plugins/sync_with_router';

export default function(dashboardType) {
  const el = document.getElementById('js-group-security-dashboard');
  const { isUnavailable, dashboardDocumentation, emptyStateSvgPath } = el.dataset;

  if (isUnavailable) {
    return new Vue({
      el,
      render(createElement) {
        return createElement(UnavailableState, {
          props: {
            link: dashboardDocumentation,
            svgPath: emptyStateSvgPath,
          },
        });
      },
    });
  }

  const router = createRouter();
  const store = createStore({
    dashboardType,
    plugins: [projectsPlugin, syncWithRouter(router)],
  });
  return new Vue({
    el,
    store,
    router,
    components: { GroupSecurityDashboardApp },
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
          vulnerableProjectsEndpoint: el.dataset.vulnerableProjectsEndpoint,
        },
      });
    },
  });
}
