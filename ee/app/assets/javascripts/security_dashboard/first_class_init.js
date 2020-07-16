import Vue from 'vue';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import FirstClassProjectSecurityDashboard from './components/first_class_project_security_dashboard.vue';
import FirstClassGroupSecurityDashboard from './components/first_class_group_security_dashboard.vue';
import FirstClassInstanceSecurityDashboard from './components/first_class_instance_security_dashboard.vue';
import UnavailableState from './components/unavailable_state.vue';
import createStore from './store';
import createRouter from './router';
import apolloProvider from './graphql/provider';

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

  const props = {
    hasVulnerabilities: Boolean(el.dataset.hasVulnerabilities),
    securityDashboardHelpPath: el.dataset.securityDashboardHelpPath,
    projectAddEndpoint: el.dataset.projectAddEndpoint,
    projectListEndpoint: el.dataset.projectListEndpoint,
    vulnerabilitiesExportEndpoint: el.dataset.vulnerabilitiesExportEndpoint,
    noVulnerabilitiesSvgPath: el.dataset.noVulnerabilitiesSvgPath,
  };

  let component;

  if (dashboardType === DASHBOARD_TYPES.PROJECT) {
    component = FirstClassProjectSecurityDashboard;
    props.projectFullPath = el.dataset.projectFullPath;
    props.userCalloutId = el.dataset.userCalloutId;
    props.userCalloutsPath = el.dataset.userCalloutsPath;
    props.showIntroductionBanner = parseBoolean(el.dataset.showIntroductionBanner);
  } else if (dashboardType === DASHBOARD_TYPES.GROUP) {
    component = FirstClassGroupSecurityDashboard;
    props.groupFullPath = el.dataset.groupFullPath;
    props.vulnerableProjectsEndpoint = el.dataset.vulnerableProjectsEndpoint;
  } else if (dashboardType === DASHBOARD_TYPES.INSTANCE) {
    component = FirstClassInstanceSecurityDashboard;
  }

  const router = createRouter();
  const store = createStore({ dashboardType });

  return new Vue({
    el,
    store,
    router,
    apolloProvider,
    provide: () => ({
      dashboardDocumentation: el.dataset.dashboardDocumentation,
      noVulnerabilitiesSvgPath: el.dataset.noVulnerabilitiesSvgPath,
      emptyStateSvgPath: el.dataset.emptyStateSvgPath,
      notEnabledScannersHelpPath: el.dataset.notEnabledScannersHelpPath,
      noPipelineRunScannersHelpPath: el.dataset.noPipelineRunScannersHelpPath,
    }),
    render(createElement) {
      return createElement(component, { props });
    },
  });
};
