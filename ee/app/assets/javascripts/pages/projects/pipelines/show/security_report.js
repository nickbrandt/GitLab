import Vue from 'vue';
import createDashboardStore from 'ee/security_dashboard/store';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline_security_dashboard.vue';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { LOADING_VULNERABILITIES_ERROR_CODES } from 'ee/security_dashboard/store/modules/vulnerabilities/constants';

const initSecurityDashboardApp = el => {
  const {
    dashboardDocumentation,
    emptyStateSvgPath,
    pipelineId,
    projectId,
    sourceBranch,
    vulnerabilitiesEndpoint,
    vulnerabilityFeedbackHelpPath,
    emptyStateUnauthorizedSvgPath,
    emptyStateForbiddenSvgPath,
  } = el.dataset;

  const loadingErrorIllustrations = {
    [LOADING_VULNERABILITIES_ERROR_CODES.UNAUTHORIZED]: emptyStateUnauthorizedSvgPath,
    [LOADING_VULNERABILITIES_ERROR_CODES.FORBIDDEN]: emptyStateForbiddenSvgPath,
  };

  return new Vue({
    el,
    store: createDashboardStore({
      dashboardType: DASHBOARD_TYPES.PIPELINE,
    }),
    render(createElement) {
      return createElement(PipelineSecurityDashboard, {
        props: {
          projectId: parseInt(projectId, 10),
          pipelineId: parseInt(pipelineId, 10),
          vulnerabilitiesEndpoint,
          vulnerabilityFeedbackHelpPath,
          sourceBranch,
          dashboardDocumentation,
          emptyStateSvgPath,
          loadingErrorIllustrations,
        },
      });
    },
  });
};

export default () => {
  const securityTab = document.getElementById('js-security-report-app');

  if (securityTab) {
    initSecurityDashboardApp(securityTab);
  }
};
