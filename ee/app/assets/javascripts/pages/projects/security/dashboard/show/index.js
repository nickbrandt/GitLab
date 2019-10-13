import Vue from 'vue';
import createRouter from 'ee/security_dashboard/store/router';
import syncWithRouter from 'ee/security_dashboard/store/plugins/sync_with_router';
import createStore from 'ee/security_dashboard/store';
import SecurityReportApp from 'ee/vue_shared/security_reports/card_security_reports_app.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

document.addEventListener('DOMContentLoaded', () => {
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
    components: {
      SecurityReportApp,
    },
    render(createElement) {
      return createElement('security-report-app', {
        props,
      });
    },
  });
});
