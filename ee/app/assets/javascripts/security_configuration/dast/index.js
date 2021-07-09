import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import DastConfigurationApp from './components/app.vue';

export default function init() {
  const el = document.querySelector('.js-dast-configuration');

  if (!el) {
    return undefined;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
  });

  const {
    securityConfigurationPath,
    fullPath,
    gitlabCiYamlEditPath,
    siteProfilesLibraryPath,
    scannerProfilesLibraryPath,
    newScannerProfilePath,
    newSiteProfilePath,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      securityConfigurationPath,
      fullPath,
      gitlabCiYamlEditPath,
      siteProfilesLibraryPath,
      scannerProfilesLibraryPath,
      newScannerProfilePath,
      newSiteProfilePath,
    },
    render(createElement) {
      return createElement(DastConfigurationApp);
    },
  });
}
