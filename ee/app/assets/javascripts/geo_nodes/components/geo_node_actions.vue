<script>
import { __, s__ } from '~/locale';
import eventHub from '../event_hub';
import { NODE_ACTIONS } from '../constants';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
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
    nodeMissingOauth: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isToggleAllowed() {
      return !this.node.primary && this.nodeEditAllowed;
    },
    nodeToggleLabel() {
      return this.node.enabled ? __('Pause replication') : __('Resume replication');
    },
    nodeToggleIcon() {
      return this.node.enabled ? 'pause' : 'play';
    },
    isSecondaryNode() {
      return !this.node.primary;
    },
  },
  methods: {
    onToggleNode() {
      eventHub.$emit('showNodeActionModal', {
        actionType: NODE_ACTIONS.TOGGLE,
        node: this.node,
        modalMessage: s__('GeoNodes|Pausing replication stops the sync process.'),
        modalActionLabel: this.nodeToggleLabel,
      });
    },
    onRemoveSecondaryNode() {
      eventHub.$emit('showNodeActionModal', {
        actionType: NODE_ACTIONS.REMOVE,
        node: this.node,
        modalKind: 'danger',
        modalMessage: s__(
          'GeoNodes|Removing a secondary node stops the sync process. It is not currently possible to add back the same node without losing some data. We only recommend setting up a new secondary node in this case. Are you sure?',
        ),
        modalActionLabel: __('Remove'),
      });
    },
    onRemovePrimaryNode() {
      eventHub.$emit('showNodeActionModal', {
        actionType: NODE_ACTIONS.REMOVE,
        node: this.node,
        modalKind: 'danger',
        modalMessage: s__(
          'GeoNodes|Removing a primary node stops the sync process for all nodes. Syncing cannot be resumed without losing some data on all secondaries. In this case we would recommend setting up all nodes from scratch. Are you sure?',
        ),
        modalActionLabel: __('Remove'),
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
    <a v-if="isSecondaryNode" :href="node.geoProjectsUrl" class="btn btn-sm mx-1 " target="_blank">
      <icon v-if="!node.current" name="external-link" /> {{ __('Open projects') }}
    </a>
    <template v-if="nodeActionsAllowed">
      <button
        v-if="nodeMissingOauth"
        type="button"
        class="btn btn-sm btn-default mx-1"
        @click="onRepairNode"
      >
        {{ s__('Repair authentication') }}
      </button>
      <button
        v-if="isToggleAllowed"
        :class="{
          'btn-warning': node.enabled,
          'btn-success': !node.enabled,
        }"
        type="button"
        class="btn btn-sm mx-1"
        @click="onToggleNode"
      >
        <icon :name="nodeToggleIcon" />
        {{ nodeToggleLabel }}
      </button>
      <a v-if="nodeEditAllowed" :href="node.editPath" class="btn btn-sm mx-1"> {{ __('Edit') }} </a>
      <button
        v-if="isSecondaryNode"
        type="button"
        class="btn btn-sm btn-danger mx-1"
        @click="onRemoveSecondaryNode"
      >
        {{ __('Remove') }}
      </button>
      <button
        v-if="!isSecondaryNode"
        type="button"
        class="btn btn-sm btn-danger mx-1"
        @click="onRemovePrimaryNode"
      >
        {{ __('Remove') }}
      </button>
    </template>
  </div>
</template>
