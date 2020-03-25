import Vue from 'vue';
import HeaderApp from 'ee/vulnerabilities/components/app.vue';
import FooterApp from 'ee/vulnerabilities/components/footer.vue';

function createFooterApp() {
  const el = document.getElementById('js-vulnerability-footer');

  if (!el) {
    return false;
  }

  const { vulnerabilityFeedbackHelpPath, hasMr } = el.dataset;
  const vulnerability = JSON.parse(el.dataset.vulnerabilityJson);
  const finding = JSON.parse(el.dataset.finding);
  const remediation = finding.remediations[0];
  const hasDownload = Boolean(
    vulnerability.state !== 'resolved' && remediation?.diff?.length && !hasMr,
  );

  const props = {
    solutionInfo: {
      solution: finding.solution,
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
