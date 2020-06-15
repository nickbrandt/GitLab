<script>
import { GlDeprecatedButton, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import eventHub from '../event_hub';
import { NODE_ACTIONS } from '../constants';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
    GlDeprecatedButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    node: {
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
    nodeMissingOauth: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isSecondaryNode() {
      return !this.node.primary;
    },
    disabledRemovalTooltip() {
      return this.nodeRemovalAllowed
        ? ''
        : s__('Geo Nodes|Cannot remove a primary node if there is a secondary node');
    },
  },
  methods: {
    onToggleNode() {
      eventHub.$emit('showNodeActionModal', {
        actionType: NODE_ACTIONS.TOGGLE,
        node: this.node,
        modalMessage: s__('GeoNodes|Pausing replication stops the sync process. Are you sure?'),
        modalActionLabel: this.nodeToggleLabel,
        modalTitle: __('Pause replication'),
      });
    },
    onRemoveSecondaryNode() {
      eventHub.$emit('showNodeActionModal', {
        actionType: NODE_ACTIONS.REMOVE,
        node: this.node,
        modalKind: 'danger',
        modalMessage: s__(
          'GeoNodes|Removing a Geo secondary node stops the synchronization to that node. Are you sure?',
        ),
        modalActionLabel: __('Remove node'),
        modalTitle: __('Remove secondary node'),
      });
    },
    onRemovePrimaryNode() {
      eventHub.$emit('showNodeActionModal', {
        actionType: NODE_ACTIONS.REMOVE,
        node: this.node,
        modalKind: 'danger',
        modalMessage: s__(
          'GeoNodes|Removing a Geo primary node stops the synchronization to all nodes. Are you sure?',
        ),
        modalActionLabel: __('Remove node'),
        modalTitle: __('Remove primary node'),
      });
    },
    onRepairNode() {
      eventHub.$emit('repairNode', this.node);
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center justify-content-end geo-node-actions">
    <a
      v-if="isSecondaryNode"
      :href="node.geoProjectsUrl"
      class="btn btn-sm mx-1 sm-column-spacing"
      target="_blank"
    >
      <icon v-if="!node.current" name="external-link" /> {{ __('Open projects') }}
    </a>
    <template v-if="nodeActionsAllowed">
      <gl-deprecated-button
        v-if="nodeMissingOauth"
        class="btn btn-sm btn-default mx-1 sm-column-spacing"
        @click="onRepairNode"
      >
        {{ s__('Repair authentication') }}
      </gl-deprecated-button>
      <a v-if="nodeEditAllowed" :href="node.editPath" class="btn btn-sm mx-1 sm-column-spacing">
        {{ __('Edit') }}
      </a>
      <gl-deprecated-button
        v-if="isSecondaryNode"
        class="btn btn-sm btn-danger mx-1 sm-column-spacing"
        :disabled="!nodeRemovalAllowed"
        @click="onRemoveSecondaryNode"
      >
        {{ __('Remove') }}
      </gl-deprecated-button>
      <div
        v-gl-tooltip.hover
        name="disabledRemovalTooltip"
        class="mx-1 sm-column-spacing"
        :title="disabledRemovalTooltip"
      >
        <gl-deprecated-button
          v-if="!isSecondaryNode"
          class="btn btn-sm btn-danger w-100"
          :disabled="!nodeRemovalAllowed"
          @click="onRemovePrimaryNode"
        >
          {{ __('Remove') }}
        </gl-deprecated-button>
      </div>
    </template>
  </div>
</template>
