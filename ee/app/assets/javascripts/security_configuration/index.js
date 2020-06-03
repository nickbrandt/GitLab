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

  // When canToggleAutoFixSettings is false in the backend, it is undefined in the frontend,
  // and when it's true in the backend, it comes in as an empty string in the frontend. The next
  // line ensures that we cast it to a boolean.
  const canToggleAutoFixSettings = el.dataset.canToggleAutoFixSettings !== undefined;

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
            canToggleAutoFixSettings,
            toggleAutofixSettingEndpoint,
          },
        },
      });
    },
  });
}
