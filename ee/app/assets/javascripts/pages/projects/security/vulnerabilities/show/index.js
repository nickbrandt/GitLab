import Vue from 'vue';
import MainApp from 'ee/vulnerabilities/components/main.vue';
import HeaderApp from 'ee/vulnerabilities/components/header.vue';
import DetailsApp from 'ee/vulnerabilities/components/details.vue';
import FooterApp from 'ee/vulnerabilities/components/footer.vue';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

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
    createIssueUrl,
    state,
    issueFeedback,
    mergeRequestFeedback,
    notesUrl,
    project,
    projectFingerprint,
    remediations,
    reportType,
    solution,
    id,
    canModifyRelatedIssues,
    relatedIssuesHelpPath,
  } = convertObjectPropsToCamelCase(JSON.parse(el.dataset.vulnerability));

  const remediation = remediations?.length ? remediations[0] : null;
  const hasDownload = Boolean(
    state !== VULNERABILITY_STATE_OBJECTS.resolved.state && remediation?.diff?.length && !hasMr,
  );
  const hasRemediation = Boolean(remediation);

  const props = {
    vulnerabilityId: id,
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
    canModifyRelatedIssues,
    project: {
      url: project.full_path,
      value: project.full_name,
    },
    relatedIssuesHelpPath,
  };

  return new Vue({
    el,
    provide: {
      reportType,
      createIssueUrl,
      projectFingerprint,
      vulnerabilityId: id,
    },
    render: h =>
      h(FooterApp, {
        props,
      }),
  });
}

function createMainApp() {
  const el = document.getElementById('js-vulnerability-main');
  const vulnerability = JSON.parse(el.dataset.vulnerability);

  return new Vue({
    el,

    provide: {
      reportType: vulnerability.report_type,
      createIssueUrl: vulnerability.create_issue_url,
      projectFingerprint: vulnerability.project_fingerprint,
      vulnerabilityId: vulnerability.id,
    },

    render: h =>
      h(MainApp, {
        props: {
          vulnerability,
        },
      }),
  });
}

window.addEventListener('DOMContentLoaded', () => {
  // createHeaderApp();
  // createDetailsApp();
  // createFooterApp();
  createMainApp();
});
