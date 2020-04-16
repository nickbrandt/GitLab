<script>
import { __, sprintf } from '~/locale';

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
    nodeRemovalAllowed: {
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
    selectiveSyncronization() {
      const { selectiveSyncType } = this.nodeDetails;

      if (selectiveSyncType === 'shards') {
        return sprintf(__('Shards (%{shards})'), {
          shards: this.node.selectiveSyncShards.join(', '),
        });
      }

      if (selectiveSyncType === 'namespaces') {
        return sprintf(__('Groups (%{groups})'), {
          groups: this.nodeDetails.namespaces.map(n => n.full_path).join(', '),
        });
      }

      return null;
    },
  },
};
</script>

<template>
  <div class="row-fluid clearfix py-3 primary-section">
    <div class="col-md-12">
      <div class="d-flex geo-node-actions-container">
        <div class="d-flex flex-column">
          <span class="text-secondary-700 js-node-url-title">{{ s__('GeoNodes|Node URL') }}</span>
          <span class="mt-1 font-weight-bold js-node-url-value">{{ node.url }}</span>
        </div>
        <geo-node-actions
          class="flex-grow-1"
          :node="node"
          :node-actions-allowed="nodeActionsAllowed"
          :node-edit-allowed="nodeEditAllowed"
          :node-removal-allowed="nodeRemovalAllowed"
          :node-missing-oauth="nodeDetails.missingOAuthApplication"
        />
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
      <div v-if="selectiveSyncronization" class="d-flex flex-column mt-2">
        <span class="text-secondary-700">{{ s__('GeoNodes|Selective synchronization') }}</span>
        <span data-testid="selectiveSync" class="mt-1 font-weight-bold">
          {{ selectiveSyncronization }}
        </span>
      </div>
      <geo-node-health-status
        :status="nodeHealthStatus"
        :status-check-timestamp="nodeDetails.statusCheckTimestamp"
      />
    </div>
  </div>
</template>
