import Vue from 'vue';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import GroupSecurityCharts from './components/group_security_charts.vue';
import InstanceSecurityCharts from './components/instance_security_charts.vue';
import ProjectSecurityCharts from './components/project_security_charts.vue';
import UnavailableState from './components/unavailable_state.vue';
import apolloProvider from './graphql/provider';
import createRouter from './router';
import createStore from './store';

export default (el, dashboardType) => {
  if (!el) {
    return null;
  }

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

  const props = {};
  const provide = {
    dashboardDocumentation: el.dataset.dashboardDocumentation,
    emptyStateSvgPath: el.dataset.emptyStateSvgPath,
    groupFullPath: el.dataset.groupFullPath,
    securityConfigurationPath: el.dataset.securityConfigurationPath,
    securityDashboardHelpPath: el.dataset.securityDashboardHelpPath,
    surveyRequestSvgPath: el.dataset.surveyRequestSvgPath,
  };

  let component;

  if (dashboardType === DASHBOARD_TYPES.GROUP) {
    component = GroupSecurityCharts;
    props.groupFullPath = el.dataset.groupFullPath;
  } else if (dashboardType === DASHBOARD_TYPES.INSTANCE) {
    component = InstanceSecurityCharts;
    provide.instanceDashboardSettingsPath = el.dataset.instanceDashboardSettingsPath;
  } else if (dashboardType === DASHBOARD_TYPES.PROJECT) {
    component = ProjectSecurityCharts;
    props.projectFullPath = el.dataset.projectFullPath;
    props.hasVulnerabilities = parseBoolean(el.dataset.hasVulnerabilities);
  }

  const router = createRouter();
  const store = createStore({ dashboardType });

  return new Vue({
    el,
    store,
    router,
    apolloProvider,
    provide: () => provide,
    render(createElement) {
      return createElement(component, { props });
    },
  });
};
