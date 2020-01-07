import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import GeoNodeFormApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-geo-node-form');

  return new Vue({
    el,
    components: {
      GeoNodeFormApp,
    },
    data() {
      const {
        dataset: { selectiveSyncTypes, syncShardsOptions, nodeData },
      } = this.$options.el;

      let jsonNodeData;
      if (nodeData) {
        jsonNodeData = JSON.parse(nodeData);
        jsonNodeData = convertObjectPropsToCamelCase(jsonNodeData, { deep: true });
        jsonNodeData = { ...jsonNodeData.node, namespaceIds: jsonNodeData.namespaceIds };
      }

      return {
        selectiveSyncTypes: JSON.parse(selectiveSyncTypes),
        syncShardsOptions: JSON.parse(syncShardsOptions),
        node: jsonNodeData,
      };
    },

    render(createElement) {
      return createElement('geo-node-form-app', {
        props: {
          selectiveSyncTypes: this.selectiveSyncTypes,
          syncShardsOptions: this.syncShardsOptions,
          node: this.node,
        },
      });
    },
  });
};
