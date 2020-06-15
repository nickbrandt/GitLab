import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { parseBoolean } from '~/lib/utils/common_utils';
import createStore from './store';
import GeoReplicableApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-geo-replicable');
  const { replicableType, geoTroubleshootingLink, geoReplicableEmptySvgPath } = el.dataset;
  const useGraphQl = parseBoolean(el.dataset.graphql);

  return new Vue({
    el,
    store: createStore({ replicableType, useGraphQl }),
    components: {
      GeoReplicableApp,
    },

    render(createElement) {
      return createElement('geo-replicable-app', {
        props: {
          geoTroubleshootingLink,
          geoReplicableEmptySvgPath,
        },
      });
    },
  });
};
