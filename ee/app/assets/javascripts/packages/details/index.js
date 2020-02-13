import Vue from 'vue';
import PackagesApp from './components/app.vue';
import Translate from '~/vue_shared/translate';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const el = document.querySelector('#js-vue-packages-detail');
  const {
    package: packageJson,
    packageFiles: packageFilesJson,
    canDelete: canDeleteStr,
    ...rest
  } = el.dataset;
  const packageEntity = JSON.parse(packageJson);
  const packageFiles = JSON.parse(packageFilesJson);
  const canDelete = canDeleteStr === 'true';

  const store = createStore({ packageEntity, packageFiles, canDelete, ...rest });
  store.dispatch('fetchPipelineInfo');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      PackagesApp,
    },
    store,
    render(createElement) {
      return createElement('packages-app');
    },
  });
};
