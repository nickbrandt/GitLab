<script>
import { GlFormGroup, GlFormInput, GlFormCheckbox, GlButton } from '@gitlab/ui';
import GeoNodeFormCore from './geo_node_form_core.vue';
import GeoNodeFormSelectiveSync from './geo_node_form_selective_sync.vue';
import GeoNodeFormCapacities from './geo_node_form_capacities.vue';

export default {
  name: 'GeoNodeForm',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    GlButton,
    GeoNodeFormCore,
    GeoNodeFormSelectiveSync,
    GeoNodeFormCapacities,
  },
  props: {
    node: {
      type: Object,
      required: false,
      default: null,
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
  data() {
    return {
      nodeData: {
        name: '',
        url: '',
        primary: false,
        internalUrl: '',
        selectiveSyncType: '',
        namespaceIds: [],
        selectiveSyncShards: [],
        reposMaxCapacity: 25,
        filesMaxCapacity: 10,
        verificationMaxCapacity: 100,
        containerRepositoriesMaxCapacity: 10,
        minimumReverificationInterval: 7,
        syncObjectStorage: false,
      },
    };
  },
  created() {
    if (this.node) {
      this.nodeData = { ...this.node };
    }
  },
};
</script>

<template>
  <form>
    <geo-node-form-core :node-data="nodeData" />
    <section class="mt-3 pl-0 col-sm-6">
      <gl-form-group>
        <gl-form-checkbox v-model="nodeData.primary">{{
          __('This is a primary node')
        }}</gl-form-checkbox>
      </gl-form-group>
      <gl-form-group
        v-if="nodeData.primary"
        :label="__('Internal URL (optional)')"
        label-for="node-internal-url-field"
        :description="
          __(
            'The URL defined on the primary node that secondary nodes should use to contact it. Defaults to URL',
          )
        "
      >
        <gl-form-input id="node-internal-url-field" v-model="nodeData.internalUrl" type="text" />
      </gl-form-group>
      <geo-node-form-selective-sync
        v-if="!nodeData.primary"
        :node-data="nodeData"
        :selective-sync-types="selectiveSyncTypes"
        :sync-shards-options="syncShardsOptions"
      />
      <geo-node-form-capacities :node-data="nodeData" />
      <gl-form-group
        v-if="!nodeData.primary"
        :label="__('Object Storage replication')"
        label-for="node-object-storage-field"
        :description="
          __(
            'If enabled, and if object storage is enabled, GitLab will handle Object Storage replication using Geo',
          )
        "
      >
        <gl-form-checkbox v-model="nodeData.syncObjectStorage">{{
          __('Allow this secondary node to replicate content on Object Storage')
        }}</gl-form-checkbox>
      </gl-form-group>
    </section>
    <section class="d-flex align-items-center mt-4">
      <gl-button variant="success">{{ __('Save') }}</gl-button>
      <gl-button class="ml-auto">{{ __('Cancel') }}</gl-button>
    </section>
  </form>
</template>
