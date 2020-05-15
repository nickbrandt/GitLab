import Vue from 'vue';
import HeaderApp from 'ee/vulnerabilities/components/header.vue';
import FooterApp from 'ee/vulnerabilities/components/footer.vue';

function createHeaderApp() {
  const el = document.getElementById('js-vulnerability-header');
  console.log('h el.dataset', el.dataset);
  console.log('h Object({}, el.dataset)', { ...el.dataset });
  const pipeline = JSON.parse(el.dataset.pipelineJson);

  const { projectFingerprint, createIssueUrl } = el.dataset;

  return new Vue({
    el,

    render: h =>
      h(HeaderApp, {
        props: {
          initialVulnerability: { ...el.dataset },
          finding: { ...el.dataset },
          pipeline,
          projectFingerprint,
          createIssueUrl,
        },
      }),
  });
}

function createFooterApp() {
  const el = document.getElementById('js-vulnerability-footer');
  console.log('f el.dataset', el.dataset);

  if (!el) {
    return false;
  }

  const {
    vulnerabilityFeedbackHelpPath,
    hasMr,
    discussionsUrl,
    state,
    issue_feedback: feedback,
    remediation,
    solution,
  } = el.dataset;
  const project = JSON.parse(el.dataset.project);
  const hasDownload = Boolean(state !== 'resolved' && remediation?.diff?.length && !hasMr);

  const props = {
    discussionsUrl,
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
  createFooterApp();
});
