import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
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
  const vulnerability = JSON.parse(el.dataset.vulnerability);

  return new Vue({
    el,
    render: h => h(DetailsApp, { props: { vulnerability } }),
  });
}

function createFooterApp() {
  const el = document.getElementById('js-vulnerability-footer');

  if (!el) {
    return false;
  }

  const {
    vulnerabilityFeedbackHelpPath,
    hasMr,
    discussionsUrl,
    state,
    issueFeedback,
    mergeRequestFeedback,
    notesUrl,
    project,
    remediations,
    solution,
  } = convertObjectPropsToCamelCase(JSON.parse(el.dataset.vulnerability));

  const remediation = remediations?.length ? remediations[0] : null;
  const hasDownload = Boolean(
    state !== VULNERABILITY_STATE_OBJECTS.resolved.state && remediation?.diff?.length && !hasMr,
  );
  const hasRemediation = Boolean(remediation);

  const props = {
    discussionsUrl,
    notesUrl,
    solutionInfo: {
      solution,
      remediation,
      hasDownload,
      hasMr,
      hasRemediation,
      vulnerabilityFeedbackHelpPath,
      isStandaloneVulnerability: true,
    },
    issueFeedback,
    mergeRequestFeedback,
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
