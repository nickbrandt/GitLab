import Vue from 'vue';
import SecurityConfigurationApp from './components/app.vue';

export default function init() {
  const el = document.getElementById('js-security-configuration');
  const {
    autoDevopsEnabled,
    autoDevopsHelpPagePath,
    features,
    helpPagePath,
    latestPipelinePath,
    autoFixEnabled,
    autoFixHelpPath,
    autoFixUserPath,
    containerScanningHelpPath,
    dependencyScanningHelpPath,
    toggleAutofixSettingEndpoint,
  } = el.dataset;

  return new Vue({
    el,
    components: {
      SecurityConfigurationApp,
    },
    render(createElement) {
      return createElement(SecurityConfigurationApp, {
        props: {
          autoDevopsEnabled,
          autoDevopsHelpPagePath,
          features: JSON.parse(features),
          helpPagePath,
          latestPipelinePath,
          autoFixSettingsProps: {
            autoFixEnabled: JSON.parse(autoFixEnabled),
            autoFixHelpPath,
            autoFixUserPath,
            containerScanningHelpPath,
            dependencyScanningHelpPath,
            toggleAutofixSettingEndpoint,
          },
        },
      });
    },
  });
}
