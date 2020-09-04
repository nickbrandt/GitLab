import Vue from 'vue';
import apolloProvider from './graphql/provider';
import DastScannerProfileForm from './components/dast_scanner_profile_form.vue';

export default () => {
  const el = document.querySelector('.js-dast-scanner-profile-form');
  if (!el) {
    return false;
  }

  const { projectFullPath, profilesLibraryPath } = el.dataset;

  const props = {
    projectFullPath,
    profilesLibraryPath,
  };

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(DastScannerProfileForm, {
        props,
      });
    },
  });
};
