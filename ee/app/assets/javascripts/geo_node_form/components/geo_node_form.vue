<script>
import { mapActions, mapGetters } from 'vuex';
import { GlFormGroup, GlFormInput, GlFormCheckbox, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
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
      type: Object,
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
        selectiveSyncNamespaceIds: [],
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
  computed: {
    ...mapGetters(['formHasError']),
    saveButtonTitle() {
      return this.node ? __('Update') : __('Save');
    },
  },
  created() {
    if (this.node) {
      this.nodeData = { ...this.node };
    }
  },
  methods: {
    ...mapActions(['saveGeoNode']),
    redirect() {
      visitUrl('/admin/geo/nodes');
    },
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
  <form>
    <geo-node-form-core :node-data="nodeData" />
    <section class="mt-3 pl-0 col-sm-6">
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
        @addSyncOption="addSyncOption"
        @removeSyncOption="removeSyncOption"
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
        <gl-form-checkbox id="node-object-storage-field" v-model="nodeData.syncObjectStorage">{{
          __('Allow this secondary node to replicate content on Object Storage')
        }}</gl-form-checkbox>
      </gl-form-group>
    </section>
    <section class="d-flex align-items-center mt-4">
      <gl-button
        id="node-save-button"
        data-qa-selector="add_node_button"
        variant="success"
        :disabled="formHasError"
        @click="saveGeoNode(nodeData)"
        >{{ saveButtonTitle }}</gl-button
      >
      <gl-button id="node-cancel-button" class="gl-ml-auto" @click="redirect">{{
        __('Cancel')
      }}</gl-button>
    </section>
  </form>
</template>
