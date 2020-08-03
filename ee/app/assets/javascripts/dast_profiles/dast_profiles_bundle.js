import Vue from 'vue';
import apolloProvider from './graphql/provider';
import DastProfiles from './components/dast_profiles.vue';

export default () => {
  const el = document.querySelector('.js-dast-profiles');

  if (!el) {
    return undefined;
  }

  const {
    dataset: { newDastSiteProfilePath, projectFullPath },
  } = el;

  const props = {
    newDastSiteProfilePath,
    projectFullPath,
  };

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(DastProfiles, {
        props,
      });
    },
  });
};
