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
      type: Object,
      required: true,
    },
    syncShardsOptions: {
      type: Array,
      required: true,
    },
  },
  computed: {
    selectiveSyncNamespaces() {
      return this.nodeData.selectiveSyncType === this.selectiveSyncTypes.NAMESPACES.value;
    },
    selectiveSyncShards() {
      return this.nodeData.selectiveSyncType === this.selectiveSyncTypes.SHARDS.value;
    },
  },
  methods: {
    addSyncOption({ key, value }) {
      this.$emit('addSyncOption', { key, value });
    },
    removeSyncOption({ key, index }) {
      this.$emit('removeSyncOption', { key, index });
    },
  },
};
</script>

<template>
  <div ref="geoNodeFormSelectiveSyncContainer">
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
      v-if="selectiveSyncNamespaces"
      :label="__('Groups to synchronize')"
      label-for="node-synchronization-namespaces-field"
      :description="__('Choose which groups you wish to synchronize to this secondary node')"
    >
      <geo-node-form-namespaces
        id="node-synchronization-namespaces-field"
        :selected-namespaces="nodeData.selectiveSyncNamespaceIds"
        @addSyncOption="addSyncOption"
        @removeSyncOption="removeSyncOption"
      />
    </gl-form-group>
    <gl-form-group
      v-if="selectiveSyncShards"
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
