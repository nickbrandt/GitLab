import Vue from 'vue';
import SecurityConfigurationApp from './components/app.vue';

export default function init() {
  const el = document.getElementById('js-security-configuration');
  const {
    autoDevOpsEnabled,
    autoDevOpsHelpPagePath,
    features,
    helpPagePath,
    latestPipelinePath,
    pipelinesHelpPagePath,
  } = el.dataset;

  return new Vue({
    el,
    components: {
      SecurityConfigurationApp,
    },
    render(createElement) {
      return createElement(SecurityConfigurationApp, {
        props: {
          autoDevOpsEnabled,
          autoDevOpsHelpPagePath,
          features: JSON.parse(features),
          helpPagePath,
          latestPipelinePath,
          pipelinesHelpPagePath,
        },
      });
    },
  });
}
