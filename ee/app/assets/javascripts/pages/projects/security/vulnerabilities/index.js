import Vue from 'vue';
import VulnerabilitiesApp from 'ee/vulnerabilities/components/vulnerabilities_app.vue';
import createStore from 'ee/security_dashboard/store';

function render() {
  const el = document.getElementById('app');

  if (!el) {
    return false;
  }

  const { dashboardDocumentation, emptyStateSvgPath, vulnerabilitiesEndpoint } = el.dataset;

  return new Vue({
    el,
    store: createStore(),
    render(createElement) {
      return createElement(VulnerabilitiesApp, {
        props: {
          emptyStateSvgPath,
          dashboardDocumentation,
          vulnerabilitiesEndpoint,
        },
      });
    },
  });
}

window.addEventListener('DOMContentLoaded', () => {
  render();
});
