<script>
import { __ } from '~/locale';

import GeoNodeHealthStatus from '../geo_node_health_status.vue';
import GeoNodeActions from '../geo_node_actions.vue';

export default {
  components: {
    GeoNodeHealthStatus,
    GeoNodeActions,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
    nodeDetails: {
      type: Object,
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
    versionMismatch: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    nodeVersion() {
      if (this.nodeDetails.version == null && this.nodeDetails.revision == null) {
        return __('Unknown');
      }
      return `${this.nodeDetails.version} (${this.nodeDetails.revision})`;
    },
    nodeHealthStatus() {
      return this.nodeDetails.healthy ? this.nodeDetails.health : this.nodeDetails.healthStatus;
    },
  },
};
</script>

<template>
  <div class="row-fluid clearfix py-3 primary-section">
    <div class="col-md-8">
      <div class="d-flex flex-column">
        <span class="text-secondary-700 js-node-url-title">{{ s__('GeoNodes|Node URL') }}</span>
        <span class="mt-1 font-weight-bold js-node-url-value">{{ node.url }}</span>
      </div>
      <div class="d-flex flex-column mt-2">
        <span class="text-secondary-700 js-node-version-title">{{
          s__('GeoNodes|GitLab version')
        }}</span>
        <span
          :class="{ 'text-danger-500': versionMismatch }"
          class="mt-1 font-weight-bold js-node-version-value"
        >
          {{ nodeVersion }}
        </span>
      </div>
      <geo-node-health-status :status="nodeHealthStatus" />
    </div>
    <geo-node-actions
      :node="node"
      :node-actions-allowed="nodeActionsAllowed"
      :node-edit-allowed="nodeEditAllowed"
      :node-missing-oauth="nodeDetails.missingOAuthApplication"
    />
  </div>
</template>
