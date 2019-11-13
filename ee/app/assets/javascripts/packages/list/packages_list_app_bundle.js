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
      const {
        dataset: { projectId, groupId, emptyListIllustration, emptyListHelpUrl, canDestroyPackage },
      } = document.querySelector(this.$options.el);

      return {
        packageListAttrs: {
          projectId,
          groupId,
          emptyListIllustration,
          emptyListHelpUrl,
          canDestroyPackage,
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
