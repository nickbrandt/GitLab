import Vue from 'vue';
import NewFeatureFlag from 'ee/feature_flags/components/new_feature_flag.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const el = document.querySelector('#js-new-feature-flag');

  return new Vue({
    el,
    components: {
      NewFeatureFlag,
    },
    render(createElement) {
      return createElement('new-feature-flag', {
        props: {
          endpoint: el.dataset.endpoint,
          path: el.dataset.featureFlagsPath,
          environmentsEndpoint: el.dataset.environmentsEndpoint,
          projectId: el.dataset.projectId,
          userCalloutsPath: el.dataset.userCalloutsPath,
          userCalloutId: el.dataset.userCalloutId,
          showUserCallout: parseBoolean(el.dataset.showUserCallout),
        },
      });
    },
  });
};
