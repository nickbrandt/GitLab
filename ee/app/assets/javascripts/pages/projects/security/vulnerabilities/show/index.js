import Vue from 'vue';
import HeaderApp from 'ee/vulnerabilities/components/header.vue';
import DetailsApp from 'ee/vulnerabilities/components/details.vue';
import FooterApp from 'ee/vulnerabilities/components/footer.vue';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';

function createHeaderApp() {
  const el = document.getElementById('js-vulnerability-header');
  const vulnerability = JSON.parse(el.dataset.vulnerability);

  return new Vue({
    el,

    render: h =>
      h(HeaderApp, {
        props: {
          initialVulnerability: vulnerability,
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

  const {
    vulnerability_feedback_help_path: vulnerabilityFeedbackHelpPath,
    has_mr: hasMr,
    discussions_url: discussionsUrl,
    state,
    issue_feedback: feedback,
    project,
    remediations,
    solution,
  } = JSON.parse(el.dataset.vulnerability);

  const remediation = remediations?.length ? remediations[0] : null;
  const hasDownload = Boolean(
    state !== VULNERABILITY_STATE_OBJECTS.resolved.state && remediation?.diff?.length && !hasMr,
  );
  const hasRemediation = Boolean(remediation);

  const props = {
    discussionsUrl,
    notesUrl,
    finding,
    solutionInfo: {
      solution: finding.solution,
      remediation: finding.remediation,
      hasDownload,
      hasMr,
      hasRemediation,
      vulnerabilityFeedbackHelpPath,
      isStandaloneVulnerability: true,
    },
    feedback,
    project: {
      url: project.full_path,
      value: project.full_name,
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
