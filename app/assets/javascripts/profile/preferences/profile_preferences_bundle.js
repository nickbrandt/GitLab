import Vue from 'vue';
import createFlash from '~/flash';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';
import ProfilePreferences from './components/profile_preferences.vue';
import { parseDataset } from './utils';

Vue.use(GlFeatureFlagsPlugin);

export default () => {
  const el = document.querySelector('#js-profile-preferences-app');
  const formEl = document.querySelector('#profile-preferences-form');

  let provide;
  try {
    provide = parseDataset(el.dataset);
  } catch (error) {
    createFlash({
      message: error.message,
      captureError: true,
      error,
    });

    return undefined;
  }

  return new Vue({
    el,
    name: 'ProfilePreferencesApp',
    provide: {
      ...provide,
      formEl,
    },
    render: (createElement) => createElement(ProfilePreferences),
  });
};
