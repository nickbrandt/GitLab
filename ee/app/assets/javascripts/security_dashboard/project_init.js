import Vue from 'vue';
import createRouter from './store/router';
import syncWithRouter from './store/plugins/sync_with_router';
import createStore from './store';
import { DASHBOARD_TYPES } from './store/constants';
import ProjectSecurityDashboard from './components/project_security_dashboard.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const securityTab = document.getElementById('js-security-report-app');

  const {
    commitId,
    commitPath,
    dashboardDocumentation,
    emptyStateSvgPath,
    hasPipelineData,
    pipelineCreated,
    pipelineId,
    pipelinePath,
    projectId,
    projectName,
    refId,
    refPath,
    securityDashboardHelpPath,
    userAvatarPath,
    userName,
    userPath,
    vulnerabilitiesEndpoint,
    vulnerabilitiesSummaryEndpoint,
    vulnerabilityFeedbackHelpPath,
  } = securityTab.dataset;

  const parsedPipelineId = parseInt(pipelineId, 10);
  const parsedHasPipelineData = parseBoolean(hasPipelineData);

  let props = {
    dashboardDocumentation,
    emptyStateSvgPath,
    hasPipelineData: parsedHasPipelineData,
    securityDashboardHelpPath,
    vulnerabilitiesEndpoint,
    vulnerabilitiesSummaryEndpoint,
    vulnerabilityFeedbackHelpPath,
  };
  if (parsedHasPipelineData) {
    props = {
      ...props,
      project: {
        id: projectId,
        name: projectName,
      },
      triggeredBy: {
        avatarPath: userAvatarPath,
        name: userName,
        path: userPath,
      },
      pipeline: {
        id: parsedPipelineId,
        created: pipelineCreated,
        path: pipelinePath,
      },
      commit: {
        id: commitId,
        path: commitPath,
      },
      branch: {
        id: refId,
        path: refPath,
      },
    };
  }

  const router = createRouter();
  const store = createStore({
    dashboardType: DASHBOARD_TYPES.PROJECT,
    plugins: [syncWithRouter(router)],
  });

  return new Vue({
    el: securityTab,
    store,
    router,
    render(createElement) {
      return createElement(ProjectSecurityDashboard, {
        props,
      });
    },
  });
};
