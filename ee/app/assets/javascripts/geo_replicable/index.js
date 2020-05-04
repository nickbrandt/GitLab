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
        dataset: { geoTroubleshootingLink, geoReplicableEmptySvgPath },
      } = this.$options.el;

      return {
        geoTroubleshootingLink,
        geoReplicableEmptySvgPath,
      };
    },

    render(createElement) {
      return createElement('geo-replicable-app', {
        props: {
          geoTroubleshootingLink: this.geoTroubleshootingLink,
          geoReplicableEmptySvgPath: this.geoReplicableEmptySvgPath,
        },
      });
    },
  });
};
