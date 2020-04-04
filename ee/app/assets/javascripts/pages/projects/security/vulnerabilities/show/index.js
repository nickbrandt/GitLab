import Vue from 'vue';
import HeaderApp from 'ee/vulnerabilities/components/header.vue';
import FooterApp from 'ee/vulnerabilities/components/footer.vue';

function createHeaderApp() {
  const el = document.getElementById('js-vulnerability-header');
  const initialVulnerability = JSON.parse(el.dataset.vulnerabilityJson);
  const pipeline = JSON.parse(el.dataset.pipelineJson);
  const finding = JSON.parse(el.dataset.findingJson);

  const { projectFingerprint, createIssueUrl } = el.dataset;

  return new Vue({
    el,

    render: h =>
      h(HeaderApp, {
        props: {
          initialVulnerability,
          finding,
          pipeline,
          projectFingerprint,
          createIssueUrl,
        },
      }),
  });
}

function createFooterApp() {
  const el = document.getElementById('js-vulnerability-footer');

  if (!el) {
    return false;
  }

  const { vulnerabilityFeedbackHelpPath, hasMr } = el.dataset;
  const vulnerability = JSON.parse(el.dataset.vulnerabilityJson);
  const finding = JSON.parse(el.dataset.findingJson);
  const { issue_feedback: feedback, remediation, solution } = finding;
  const hasDownload = Boolean(
    vulnerability.state !== 'resolved' && remediation?.diff?.length && !hasMr,
  );

  const props = {
    solutionInfo: {
      solution,
      remediation,
      hasDownload,
      hasMr,
      hasRemediation: Boolean(remediation),
      vulnerabilityFeedbackHelpPath,
      isStandaloneVulnerability: true,
    },
    feedback,
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

window.addEventListener('DOMContentLoaded', () => {
  createHeaderApp();
  createFooterApp();
});
