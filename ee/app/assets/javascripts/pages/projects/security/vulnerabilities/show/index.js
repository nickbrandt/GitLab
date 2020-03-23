import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import HeaderApp from 'ee/vulnerabilities/components/app.vue';
import FooterApp from 'ee/vulnerabilities/components/footer.vue';

function createFooterApp() {
  const el = document.getElementById('js-vulnerability-footer');

  if (!el) {
    return false;
  }

  const { solution, vulnerabilityFeedbackHelpPath, vulnerabilityState } = el.dataset;
  const hasMr = parseBoolean(el.dataset.hasMr);
  const remediation = JSON.parse(el.dataset.remediation);
  const finding = JSON.parse(el.dataset.finding);
  const hasDownload = Boolean(
    vulnerabilityState !== 'resolved' && remediation?.diff?.length && !hasMr,
  );

  const props = {
    solutionCard: {
      solution,
      remediation,
      hasDownload,
      hasMr,
      hasRemediation: Boolean(remediation),
      vulnerabilityFeedbackHelpPath,
      isStandaloneVulnerability: true,
    },
    feedback: finding.issue_feedback,
    project: {
      url: finding.project.full_path,
      value: finding.project.full_name,
    },
  };

  return new Vue({
    el,
    render: h =>
      h(FooterApp, {
        props,
      }),
  });
}

function createHeaderApp() {
  const el = document.getElementById('js-vulnerability-management-app');
  const vulnerability = JSON.parse(el.dataset.vulnerabilityJson);
  const pipeline = JSON.parse(el.dataset.pipelineJson);

  const { projectFingerprint, createIssueUrl } = el.dataset;

  return new Vue({
    el,

    render: h =>
      h(HeaderApp, {
        props: {
          vulnerability,
          pipeline,
          projectFingerprint,
          createIssueUrl,
        },
      }),
  });
}

window.addEventListener('DOMContentLoaded', () => {
  createHeaderApp();
  createFooterApp();
});
