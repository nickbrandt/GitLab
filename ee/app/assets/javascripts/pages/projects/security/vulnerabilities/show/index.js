import Vue from 'vue';
import MainApp from 'ee/vulnerabilities/components/main.vue';

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
        props: { vulnerability },
      }),
  });
}

window.addEventListener('DOMContentLoaded', () => {
  // createHeaderApp();
  // createDetailsApp();
  // createFooterApp();
  createMainApp();
});
