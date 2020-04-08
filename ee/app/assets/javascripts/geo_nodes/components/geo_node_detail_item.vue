<script>
import popover from '~/vue_shared/directives/popover';

import { VALUE_TYPE, CUSTOM_TYPE } from '../constants';

import GeoNodeSyncSettings from './geo_node_sync_settings.vue';
import GeoNodeEventStatus from './geo_node_event_status.vue';
import GeoNodeSyncProgress from './geo_node_sync_progress.vue';

export default {
  components: {
    GeoNodeSyncSettings,
    GeoNodeEventStatus,
    GeoNodeSyncProgress,
  },
  directives: {
    popover,
  },
  props: {
    itemTitle: {
      type: String,
      required: true,
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
    itemValue: {
      type: [Object, String, Number],
      required: true,
    },
    itemValueStale: {
      type: Boolean,
      required: false,
      default: false,
    },
    itemValueStaleTooltip: {
      type: String,
      required: false,
      default: '',
    },
    itemValueType: {
      type: String,
      required: true,
    },
    customType: {
      type: String,
      required: false,
      default: '',
    },
    eventTypeLogStatus: {
      type: Boolean,
      required: false,
      default: false,
    },
    featureDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    detailsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasHelpInfo() {
      return typeof this.helpInfo === 'object';
    },
    isValueTypePlain() {
      return this.itemValueType === VALUE_TYPE.PLAIN;
    },
    isValueTypeGraph() {
      return this.itemValueType === VALUE_TYPE.GRAPH;
    },
    isValueTypeCustom() {
      return this.itemValueType === VALUE_TYPE.CUSTOM;
    },
    isCustomTypeSync() {
      return this.customType === CUSTOM_TYPE.SYNC;
    },
  },
};
</script>

<template>
  <div v-if="!featureDisabled" class="mt-2 ml-2 node-detail-item">
    <div class="d-flex align-items-center text-secondary-700">
      <span class="node-detail-title">{{ itemTitle }}</span>
    </div>
    <div v-if="isValueTypePlain" :class="cssClass" class="mt-1 node-detail-value">
      {{ itemValue }}
    </div>
    <geo-node-sync-progress
      v-if="isValueTypeGraph"
      :item-title="itemTitle"
      :item-value="itemValue"
      :item-value-stale="itemValueStale"
      :item-value-stale-tooltip="itemValueStaleTooltip"
      :details-path="detailsPath"
      :class="{ 'd-flex': itemValueStale }"
      class="mt-1"
    />
    <template v-if="isValueTypeCustom">
      <geo-node-sync-settings
        v-if="isCustomTypeSync"
        :sync-status-unavailable="itemValue.syncStatusUnavailable"
        :selective-sync-type="itemValue.selectiveSyncType"
        :last-event="itemValue.lastEvent"
        :cursor-last-event="itemValue.cursorLastEvent"
      />
      <geo-node-event-status
        v-else
        :event-id="itemValue.eventId"
        :event-time-stamp="itemValue.eventTimeStamp"
        :event-type-log-status="eventTypeLogStatus"
      />
    </template>
  </div>
</template>
