import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import HeaderApp from 'ee/vulnerabilities/components/app.vue';

function createSolutionCardApp() {
  const el = document.getElementById('js-vulnerability-solution');

  if (!el) {
    return false;
  }

  const { solution, vulnerabilityFeedbackHelpPath, vulnerabilityState } = el.dataset;
  const hasMr = parseBoolean(el.dataset.hasMr);
  const remediation = JSON.parse(el.dataset.remediation);
  const hasDownload = Boolean(
    vulnerabilityState !== 'resolved' && remediation?.diff?.length && !hasMr,
  );

  const props = {
    solution,
    remediation,
    hasDownload,
    hasMr,
    hasRemediation: Boolean(remediation),
    vulnerabilityFeedbackHelpPath,
    isStandaloneVulnerability: true,
  };

  return new Vue({
    el,
    render: h =>
      h(SolutionCard, {
        props,
      }),
  });
}

function createHeaderApp() {
  const el = document.getElementById('js-vulnerability-show-header');
  const { state, id } = el.dataset;

  return new Vue({
    el,
    render: h => h(HeaderApp, { props: { state, id: Number(id) } }),
  });
}

window.addEventListener('DOMContentLoaded', () => {
  createHeaderApp();
  createSolutionCardApp();
});
