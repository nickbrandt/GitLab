import Vue from 'vue';
import HeaderApp from 'ee/vulnerabilities/components/header.vue';
import DetailsApp from 'ee/vulnerabilities/components/details.vue';
import FooterApp from 'ee/vulnerabilities/components/footer.vue';

function createHeaderApp() {
  const el = document.getElementById('js-vulnerability-header');
  const initialVulnerability = JSON.parse(el.dataset.vulnerabilityJson);
  const pipeline = JSON.parse(el.dataset.pipelineJson);
  const finding = JSON.parse(el.dataset.findingJson);

  const { projectFingerprint, createIssueUrl, createMrUrl } = el.dataset;

  return new Vue({
    el,

    render: h =>
      h(HeaderApp, {
        props: {
          createMrUrl,
          initialVulnerability,
          finding,
          pipeline,
          projectFingerprint,
          createIssueUrl,
        },
      }),
  });
}

function createDetailsApp() {
  const el = document.getElementById('js-vulnerability-details');
  const vulnerability = JSON.parse(el.dataset.vulnerabilityJson);
  const finding = JSON.parse(el.dataset.findingJson);

  return new Vue({
    el,
    render: h => h(DetailsApp, { props: { vulnerability, finding } }),
  });
}

function createFooterApp() {
  const el = document.getElementById('js-vulnerability-footer');

  if (!el) {
    return false;
  }

  const { vulnerabilityFeedbackHelpPath, hasMr, discussionsUrl, notesUrl } = el.dataset;
  const vulnerability = JSON.parse(el.dataset.vulnerabilityJson);
  const finding = JSON.parse(el.dataset.findingJson);
  const hasDownload = Boolean(
    vulnerability.state !== 'resolved' && finding.remediation?.diff?.length && !hasMr,
  );

  const props = {
    discussionsUrl,
    notesUrl,
    finding,
    solutionInfo: {
      solution: finding.solution,
      remediation: finding.remediation,
      hasDownload,
      hasMr,
      vulnerabilityFeedbackHelpPath,
      isStandaloneVulnerability: true,
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
  createDetailsApp();
  createFooterApp();
});
