import Vue from 'vue';
import { parseBooleanDataAttributes } from '~/lib/utils/dom_utils';
import SecurityConfigurationApp from './components/app.vue';
import NewSecurityConfigurationApp from './components/new/app.vue';

export const initSecurityConfiguration = (el) => {
  if (!el) {
    return null;
  }

  const {
    autoDevopsHelpPagePath,
    autoDevopsPath,
    features,
    helpPagePath,
    latestPipelinePath,
    autoFixEnabled,
    autoFixHelpPath,
    autoFixUserPath,
    containerScanningHelpPath,
    dependencyScanningHelpPath,
    toggleAutofixSettingEndpoint,
    createSastMergeRequestPath,
    gitlabCiHistoryPath,
  } = el.dataset;

  const AppComponent = gon.features?.newSecurityConfiguration
    ? NewSecurityConfigurationApp
    : SecurityConfigurationApp;

  return new Vue({
    el,
    render(createElement) {
      return createElement(AppComponent, {
        props: {
          autoDevopsHelpPagePath,
          autoDevopsPath,
          features: JSON.parse(features),
          helpPagePath,
          latestPipelinePath,
          createSastMergeRequestPath,
          ...parseBooleanDataAttributes(el, [
            'autoDevopsEnabled',
            'canEnableAutoDevops',
            'gitlabCiPresent',
          ]),
          gitlabCiHistoryPath,
          autoFixSettingsProps: {
            autoFixEnabled: JSON.parse(autoFixEnabled),
            autoFixHelpPath,
            autoFixUserPath,
            containerScanningHelpPath,
            dependencyScanningHelpPath,
            toggleAutofixSettingEndpoint,
            ...parseBooleanDataAttributes(el, ['canToggleAutoFixSettings']),
          },
        },
      });
    },
  });
};
