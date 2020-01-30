import Vue from 'vue';
import createDashboardStore from 'ee/security_dashboard/store';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline_security_dashboard.vue';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';

const initSecurityDashboardApp = el => {
  const {
    dashboardDocumentation,
    emptyStateSvgPath,
    pipelineId,
    projectId,
    sourceBranch,
    vulnerabilitiesEndpoint,
    vulnerabilityFeedbackHelpPath,
  } = el.dataset;

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
