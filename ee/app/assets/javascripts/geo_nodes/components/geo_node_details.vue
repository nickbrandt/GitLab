<script>
/* eslint-disable vue/no-side-effects-in-computed-properties */
import { GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

import NodeDetailsSectionMain from './node_detail_sections/node_details_section_main.vue';
import NodeDetailsSectionSync from './node_detail_sections/node_details_section_sync.vue';
import NodeDetailsSectionVerification from './node_detail_sections/node_details_section_verification.vue';
import NodeDetailsSectionOther from './node_detail_sections/node_details_section_other.vue';

export default {
  components: {
    GlLink,
    NodeDetailsSectionMain,
    NodeDetailsSectionSync,
    NodeDetailsSectionVerification,
    NodeDetailsSectionOther,
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
    geoTroubleshootingHelpPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showAdvanceItems: false,
      errorMessage: '',
    };
  },
  computed: {
    hasError() {
      if (!this.nodeDetails.healthy) {
        this.errorMessage = this.nodeDetails.health;
      }
      return !this.nodeDetails.healthy;
    },
    hasVersionMismatch() {
      if (
        this.nodeDetails.version !== this.nodeDetails.primaryVersion ||
        this.nodeDetails.revision !== this.nodeDetails.primaryRevision
      ) {
        this.errorMessage = s__('GeoNodes|GitLab version does not match the primary node version');
        return true;
      }
      return false;
    },
  },
};
</script>

<template>
  <div class="card-body p-0">
    <node-details-section-main
      :node="node"
      :node-details="nodeDetails"
      :node-actions-allowed="nodeActionsAllowed"
      :node-edit-allowed="nodeEditAllowed"
      :version-mismatch="hasVersionMismatch"
    />
    <node-details-section-sync v-if="!node.primary" :node-details="nodeDetails" />
    <node-details-section-verification
      v-if="nodeDetails.repositoryVerificationEnabled"
      :node-details="nodeDetails"
      :node-type-primary="node.primary"
    />
    <node-details-section-other
      :node="node"
      :node-details="nodeDetails"
      :node-type-primary="node.primary"
    />
    <div v-if="hasError || hasVersionMismatch">
      <p class="p-3 mb-0 bg-danger-100 text-danger-500">
        {{ errorMessage }}
        <gl-link :href="geoTroubleshootingHelpPath">{{
          s__('Geo|Please refer to Geo Troubleshooting.')
        }}</gl-link>
      </p>
    </div>
  </div>
</template>
