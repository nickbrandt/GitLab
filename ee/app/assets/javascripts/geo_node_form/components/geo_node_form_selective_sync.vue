<script>
import { GlFormGroup, GlFormSelect } from '@gitlab/ui';
import GeoNodeFormNamespaces from './geo_node_form_namespaces.vue';
import GeoNodeFormShards from './geo_node_form_shards.vue';

export default {
  name: 'GeoNodeFormSelectiveSync',
  components: {
    GlFormGroup,
    GlFormSelect,
    GeoNodeFormNamespaces,
    GeoNodeFormShards,
  },
  props: {
    nodeData: {
      type: Object,
      required: true,
    },
    selectiveSyncTypes: {
      type: Array,
      required: true,
    },
    syncShardsOptions: {
      type: Array,
      required: true,
    },
  },
  methods: {
    addSyncOption({ key, value }) {
      this.nodeData[key].push(value);
    },
    removeSyncOption({ key, index }) {
      this.nodeData[key].splice(index, 1);
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="__('Selective synchronization')"
      label-for="node-selective-synchronization-field"
    >
      <gl-form-select
        id="node-selective-synchronization-field"
        v-model="nodeData.selectiveSyncType"
        :options="selectiveSyncTypes"
        value-field="value"
        text-field="label"
        class="col-sm-6"
      />
    </gl-form-group>
    <gl-form-group
      v-if="nodeData.selectiveSyncType === 'namespaces'"
      :label="__('Groups to synchronize')"
      label-for="node-synchronization-namespaces-field"
      :description="__('Choose which groups you wish to synchronize to this secondary node')"
    >
      <geo-node-form-namespaces
        id="node-synchronization-namespaces-field"
        :selected-namespaces="nodeData.namespaceIds"
        @addSyncOption="addSyncOption"
        @removeSyncOption="removeSyncOption"
      />
    </gl-form-group>
    <gl-form-group
      v-if="nodeData.selectiveSyncType === 'shards'"
      :label="__('Shards to synchronize')"
      label-for="node-synchronization-shards-field"
      :description="__('Choose which shards you wish to synchronize to this secondary node')"
    >
      <geo-node-form-shards
        id="node-synchronization-shards-field"
        :selected-shards="nodeData.selectiveSyncShards"
        :sync-shards-options="syncShardsOptions"
        @addSyncOption="addSyncOption"
        @removeSyncOption="removeSyncOption"
      />
    </gl-form-group>
  </div>
</template>
