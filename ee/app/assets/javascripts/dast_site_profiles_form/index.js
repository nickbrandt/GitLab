import Vue from 'vue';
import apolloProvider from './graphql/provider';
import DastSiteProfileForm from './components/dast_site_profile_form.vue';

export default () => {
  const el = document.querySelector('.js-dast-site-profile-form');
  if (!el) {
    return;
  }

  const { fullPath, profilesLibraryPath } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(DastSiteProfileForm, {
        props: {
          fullPath,
          profilesLibraryPath,
        },
      });
    },
  });
};
