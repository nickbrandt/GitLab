import Vue from 'vue';
import { GlEmptyState } from '@gitlab/ui';
import createDashboardStore from 'ee/security_dashboard/store';
import SecurityDashboardApp from 'ee/security_dashboard/components/app.vue';
import { s__ } from '~/locale';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

const initSecurityDashboardApp = el => {
  const {
    dashboardDocumentation,
    emptyStateSvgPath,
    pipelineId,
    projectId,
    vulnerabilitiesEndpoint,
    vulnerabilityFeedbackHelpPath,
  } = el.dataset;

  return new Vue({
    el,
    store: createDashboardStore(),
    render(createElement) {
      return createElement(SecurityDashboardApp, {
        props: {
          lockToProject: {
            id: parseInt(projectId, 10),
          },
          pipelineId: parseInt(pipelineId, 10),
          vulnerabilitiesEndpoint,
          vulnerabilityFeedbackHelpPath,
        },
        scopedSlots: {
          emptyState: () =>
            createElement(GlEmptyState, {
              props: {
                title: s__(`No vulnerabilities found for this pipeline`),
                svgPath: emptyStateSvgPath,
                description: s__(
                  `While it's rare to have no vulnerabilities for your pipeline, it can happen. In any event, we ask that you double check your settings to make sure all security scanning jobs have passed successfully.`,
                ),
                primaryButtonLink: dashboardDocumentation,
                primaryButtonText: s__(
                  'Security Reports|Learn more about setting up your dashboard',
                ),
              },
            }),
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
