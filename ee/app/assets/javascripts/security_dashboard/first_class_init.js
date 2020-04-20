import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import FirstClassProjectSecurityDashboard from './components/first_class_project_security_dashboard.vue';
import FirstClassGroupSecurityDashboard from './components/first_class_group_security_dashboard.vue';
import FirstClassInstanceSecurityDashboard from './components/first_class_instance_security_dashboard.vue';
import UnavailableState from './components/unavailable_state.vue';
import createStore from './store';
import createRouter from './store/router';
import projectsPlugin from './store/plugins/projects';
import projectSelector from './store/plugins/project_selector';
import syncWithRouter from './store/plugins/sync_with_router';

const isRequired = message => {
  throw new Error(message);
};

export default (
  /* eslint-disable @gitlab/require-i18n-strings */
  el = isRequired('No element was passed to the security dashboard initializer'),
  dashboardType = isRequired('No dashboard type was passed to the security dashboard initializer'),
  /* eslint-enable @gitlab/require-i18n-strings */
) => {
  if (el.dataset.isUnavailable) {
    return new Vue({
      el,
      render(createElement) {
        return createElement(UnavailableState, {
          props: {
            link: el.dataset.dashboardDocumentation,
            svgPath: el.dataset.emptyStateSvgPath,
          },
        });
      },
    });
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const props = {
    emptyStateSvgPath: el.dataset.emptyStateSvgPath,
    dashboardDocumentation: el.dataset.dashboardDocumentation,
    hasPipelineData: Boolean(el.dataset.hasPipelineData),
    securityDashboardHelpPath: el.dataset.securityDashboardHelpPath,
    projectAddEndpoint: el.dataset.projectAddEndpoint,
    projectListEndpoint: el.dataset.projectListEndpoint,
  };

  let component;

  if (dashboardType === DASHBOARD_TYPES.PROJECT) {
    component = FirstClassProjectSecurityDashboard;
    props.projectFullPath = el.dataset.projectFullPath;
    props.vulnerabilitiesExportEndpoint = el.dataset.vulnerabilitiesExportEndpoint;
  } else if (dashboardType === DASHBOARD_TYPES.GROUP) {
    component = FirstClassGroupSecurityDashboard;
    props.groupFullPath = el.dataset.groupFullPath;
    props.vulnerableProjectsEndpoint = el.dataset.vulnerableProjectsEndpoint;
  } else if (dashboardType === DASHBOARD_TYPES.INSTANCE) {
    component = FirstClassInstanceSecurityDashboard;
    props.vulnerableProjectsEndpoint = el.dataset.vulnerableProjectsEndpoint;
  }

  const router = createRouter();
  const store = createStore({
    dashboardType,
    plugins: [projectSelector, projectsPlugin, syncWithRouter(router)],
  });

  return new Vue({
    el,
    store,
    router,
    apolloProvider,
    render(createElement) {
      return createElement(component, { props });
    },
  });
};
