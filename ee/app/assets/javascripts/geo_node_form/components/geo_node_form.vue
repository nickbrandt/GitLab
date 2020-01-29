<script>
import { GlFormGroup, GlFormInput, GlFormCheckbox, GlButton } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import GeoNodeFormCore from './geo_node_form_core.vue';
import GeoNodeFormCapacities from './geo_node_form_capacities.vue';

export default {
  name: 'GeoNodeForm',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    GlButton,
    GeoNodeFormCore,
    GeoNodeFormCapacities,
  },
  props: {
    node: {
      type: Object,
      required: false,
      default: null,
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
  created() {
    if (this.node) {
      this.nodeData = { ...this.node };
    }
  },
  methods: {
    redirect() {
      visitUrl('/admin/geo/nodes');
    },
  },
};
</script>

<template>
  <form>
    <geo-node-form-core :node-data="nodeData" />
    <section class="mt-3 pl-0 col-sm-6">
      <gl-form-group>
        <gl-form-checkbox id="node-primary-field" v-model="nodeData.primary">{{
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
      <gl-button id="node-save-button" variant="success">{{ __('Save') }}</gl-button>
      <gl-button id="node-cancel-button" class="ml-auto" @click="redirect">{{
        __('Cancel')
      }}</gl-button>
    </section>
  </form>
</template>
