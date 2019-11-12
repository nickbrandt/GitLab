import Vue from 'vue';
import PackagesListApp from './components/packages_list_app.vue';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

export default () =>
  new Vue({
    el: '#js-vue-packages-list',
    components: {
      PackagesListApp,
    },
    data() {
      const { dataset } = document.querySelector(this.$options.el);

      return {
        packageListAttrs: {
          projectId: dataset.projectId,
          emptyListIllustration: dataset.emptyListIllustration,
          emptyListHelpUrl: dataset.emptyListHelpUrl,
          canDestroyPackage: dataset.canDestroyPackage,
        },
      };
    },
    render(createElement) {
      return createElement('packages-list-app', {
        props: {
          ...this.packageListAttrs,
        },
      });
    },
  });
