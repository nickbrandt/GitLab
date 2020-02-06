import Vue from 'vue';
import PackagesApp from './components/app.vue';
import Translate from '~/vue_shared/translate';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const { dataset } = document.querySelector('#js-vue-packages-detail');
  const packageEntity = JSON.parse(dataset.package);
  const packageFiles = JSON.parse(dataset.packageFiles);
  const canDelete = dataset.canDelete === 'true';

  const store = createStore({ packageEntity, packageFiles });
  store.dispatch('fetchPipelineInfo');

  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-vue-packages-detail',
    components: {
      PackagesApp,
    },
    store,
    data() {
      return {
        canDelete,
        destroyPath: dataset.destroyPath,
        emptySvgPath: dataset.svgPath,
        npmPath: dataset.npmPath,
        npmHelpPath: dataset.npmHelpPath,
        mavenPath: dataset.mavenPath,
        mavenHelpPath: dataset.mavenHelpPath,
        conanPath: dataset.conanPath,
        conanHelpPath: dataset.conanHelpPath,
        nugetPath: dataset.nugetPath,
        nugetHelpPath: dataset.nugetHelpPath,
      };
    },
    render(createElement) {
      return createElement('packages-app', {
        props: {
          canDelete: this.canDelete,
          destroyPath: this.destroyPath,
          emptySvgPath: this.emptySvgPath,
          npmPath: this.npmPath,
          npmHelpPath: this.npmHelpPath,
          mavenPath: this.mavenPath,
          mavenHelpPath: this.mavenHelpPath,
          conanPath: this.conanPath,
          conanHelpPath: this.conanHelpPath,
          nugetPath: this.nugetPath,
          nugetHelpPath: this.nugetHelpPath,
        },
      });
    },
  });
};
