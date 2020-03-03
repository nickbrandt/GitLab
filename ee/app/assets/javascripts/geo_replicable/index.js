import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import createStore from './store';
import GeoReplicableApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-geo-replicable');
  const { replicableType } = el.dataset;

  return new Vue({
    el,
    store: createStore(replicableType),
    components: {
      GeoReplicableApp,
    },
    data() {
      const {
        dataset: { geoSvgPath, issuesSvgPath, geoTroubleshootingLink },
      } = this.$options.el;

      return {
        geoSvgPath,
        issuesSvgPath,
        geoTroubleshootingLink,
      };
    },

    render(createElement) {
      return createElement('geo-replicable-app', {
        props: {
          geoSvgPath: this.geoSvgPath,
          issuesSvgPath: this.issuesSvgPath,
          geoTroubleshootingLink: this.geoTroubleshootingLink,
        },
      });
    },
  });
};
