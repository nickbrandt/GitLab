import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import SecurityReportApp from 'ee/vue_shared/security_reports/split_security_reports_app.vue';
import createStore from 'ee/vue_shared/security_reports/store';
import { updateBadgeCount } from './utils';

Vue.use(Translate);

export default () => {
  const securityTab = document.getElementById('js-security-report-app');

  // They are being rendered under the same condition
  if (securityTab) {
    const datasetOptions = securityTab.dataset;
    const {
      headBlobPath,
      sourceBranch,
      sastHeadPath,
      sastHelpPath,
      dependencyScanningHeadPath,
      dependencyScanningHelpPath,
      vulnerabilityFeedbackPath,
      vulnerabilityFeedbackHelpPath,
      createVulnerabilityFeedbackIssuePath,
      createVulnerabilityFeedbackMergeRequestPath,
      createVulnerabilityFeedbackDismissalPath,
      dastHeadPath,
      sastContainerHeadPath,
      dastHelpPath,
      sastContainerHelpPath,
    } = datasetOptions;
    const pipelineId = parseInt(datasetOptions.pipelineId, 10);

    const store = createStore();

    // Tab content
    // eslint-disable-next-line no-new
    new Vue({
      el: securityTab,
      store,
      components: {
        SecurityReportApp,
      },
      render(createElement) {
        return createElement('security-report-app', {
          props: {
            headBlobPath,
            sourceBranch,
            sastHeadPath,
            sastHelpPath,
            dependencyScanningHeadPath,
            dependencyScanningHelpPath,
            vulnerabilityFeedbackPath,
            vulnerabilityFeedbackHelpPath,
            createVulnerabilityFeedbackIssuePath,
            createVulnerabilityFeedbackMergeRequestPath,
            createVulnerabilityFeedbackDismissalPath,
            pipelineId,
            dastHeadPath,
            sastContainerHeadPath,
            dastHelpPath,
            sastContainerHelpPath,
            canCreateIssue: Boolean(createVulnerabilityFeedbackIssuePath),
            canCreateMergeRequest: Boolean(createVulnerabilityFeedbackMergeRequestPath),
            canDismissVulnerability: Boolean(createVulnerabilityFeedbackDismissalPath),
          },
          on: {
            updateBadgeCount: count => {
              updateBadgeCount('.js-sast-counter', count);
            },
          },
        });
      },
    });
  }
};
