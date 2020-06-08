import Vue from 'vue';
import EditFeatureFlag from 'ee/feature_flags/components/edit_feature_flag.vue';

export default () => {
  const el = document.querySelector('#js-edit-feature-flag');

  return new Vue({
    el,
    components: {
      EditFeatureFlag,
    },
    render(createElement) {
      return createElement('edit-feature-flag', {
        props: {
          endpoint: el.dataset.endpoint,
          path: el.dataset.featureFlagsPath,
          environmentsEndpoint: el.dataset.environmentsEndpoint,
          projectId: el.dataset.projectId,
        },
      });
    },
  });
};
