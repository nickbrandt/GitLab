import Vue from 'vue';
import createRouter from './store/router';
import syncWithRouter from './store/plugins/sync_with_router';
import createStore from './store';
import ProjectSecurityDashboard from './components/project_security_dashboard.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const securityTab = document.getElementById('js-security-report-app');

  const {
    hasPipelineData,
    userPath,
    userAvatarPath,
    pipelineCreated,
    pipelinePath,
    userName,
    commitId,
    commitPath,
    refId,
    refPath,
    pipelineId,
    projectId,
    projectName,
    dashboardDocumentation,
    emptyStateSvgPath,
    vulnerabilitiesEndpoint,
    vulnerabilitiesSummaryEndpoint,
    vulnerabilityFeedbackHelpPath,
    securityDashboardHelpPath,
    emptyStateIllustrationPath,
  } = securityTab.dataset;

  const parsedPipelineId = parseInt(pipelineId, 10);
  const parsedHasPipelineData = parseBoolean(hasPipelineData);

  let props = {
    hasPipelineData: parsedHasPipelineData,
    dashboardDocumentation,
    emptyStateSvgPath,
    vulnerabilitiesEndpoint,
    vulnerabilitiesSummaryEndpoint,
    vulnerabilityFeedbackHelpPath,
    securityDashboardHelpPath,
    emptyStateIllustrationPath,
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
  const store = createStore({ plugins: [syncWithRouter(router)] });

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
