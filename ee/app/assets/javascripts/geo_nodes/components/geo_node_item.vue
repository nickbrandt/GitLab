<script>
import { GlLink } from '@gitlab/ui';

import eventHub from '../event_hub';

import GeoNodeHeader from './geo_node_header.vue';
import GeoNodeDetails from './geo_node_details.vue';

export default {
  components: {
    GlLink,
    GeoNodeHeader,
    GeoNodeDetails,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
    primaryNode: {
      type: Boolean,
      required: true,
    },
    nodeActionsAllowed: {
      type: Boolean,
      required: true,
    },
    nodeEditAllowed: {
      type: Boolean,
      required: true,
    },
    geoTroubleshootingHelpPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isNodeDetailsLoading: true,
      isNodeDetailsFailed: false,
      nodeHealthStatus: '',
      errorMessage: '',
      nodeDetails: {},
    };
  },
  computed: {
    showNodeDetails() {
      if (!this.isNodeDetailsLoading) {
        return !this.isNodeDetailsFailed;
      }
      return false;
    },
  },
  created() {
    eventHub.$on('nodeDetailsLoaded', this.handleNodeDetails);
  },
  mounted() {
    this.handleMounted();
  },
  beforeDestroy() {
    eventHub.$off('nodeDetailsLoaded', this.handleNodeDetails);
  },
  methods: {
    handleNodeDetails(nodeDetails) {
      if (this.node.id === nodeDetails.id) {
        this.isNodeDetailsLoading = false;
        this.isNodeDetailsFailed = false;
        this.errorMessage = '';
        this.nodeDetails = nodeDetails;
        this.nodeHealthStatus = nodeDetails.health;
      }
    },
    handleMounted() {
      eventHub.$emit('pollNodeDetails', this.node);
    },
  },
};
</script>

<template>
  <div :class="{ 'node-action-active': node.nodeActionActive }" class="card">
    <geo-node-header
      :node="node"
      :node-details="nodeDetails"
      :node-details-loading="isNodeDetailsLoading"
      :node-details-failed="isNodeDetailsFailed"
    />
    <geo-node-details
      v-if="showNodeDetails"
      :node="node"
      :node-details="nodeDetails"
      :node-edit-allowed="nodeEditAllowed"
      :node-actions-allowed="nodeActionsAllowed"
      :geo-troubleshooting-help-path="geoTroubleshootingHelpPath"
    />
    <div v-if="isNodeDetailsFailed">
      <p class="p-3 mb-0 bg-danger-100 text-danger-500">
        {{ errorMessage
        }}<gl-link :href="geoTroubleshootingHelpPath">{{
          s__('Geo|Please refer to Geo Troubleshooting.')
        }}</gl-link>
      </p>
    </div>
  </div>
</template>
