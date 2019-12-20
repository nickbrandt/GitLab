<script>
import { s__ } from '~/locale';
import popover from '~/vue_shared/directives/popover';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import StackedProgressBar from '~/vue_shared/components/stacked_progress_bar.vue';

import { VALUE_TYPE, CUSTOM_TYPE } from '../constants';

import GeoNodeSyncSettings from './geo_node_sync_settings.vue';
import GeoNodeEventStatus from './geo_node_event_status.vue';

export default {
  components: {
    Icon,
    StackedProgressBar,
    GeoNodeSyncSettings,
    GeoNodeEventStatus,
  },
  directives: {
    popover,
    tooltip,
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
    successLabel: {
      type: String,
      required: false,
      default: s__('GeoNodes|Synced'),
    },
    failureLabel: {
      type: String,
      required: false,
      default: s__('GeoNodes|Failed'),
    },
    neutralLabel: {
      type: String,
      required: false,
      default: s__('GeoNodes|Out of sync'),
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
    helpInfo: {
      type: [Boolean, Object],
      required: false,
      default: false,
    },
    featureDisabled: {
      type: Boolean,
      required: false,
      default: false,
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
    popoverConfig() {
      return {
        html: true,
        trigger: 'click',
        placement: 'top',
        template: `
            <div class="popover geo-node-detail-popover" role="tooltip">
              <div class="arrow"></div>
              <p class="popover-header"></p>
              <div class="popover-body"></div>
            </div>
          `,
        title: this.helpInfo.title,
        content: `
            <a href="${this.helpInfo.url}">
              ${this.helpInfo.urlText}
            </a>
          `,
      };
    },
  },
};
</script>

<template>
  <div v-if="!featureDisabled" class="mt-2 ml-2 node-detail-item">
    <div class="d-flex align-items-center text-secondary-700">
      <span class="node-detail-title">{{ itemTitle }}</span>
      <icon
        v-if="hasHelpInfo"
        v-popover="popoverConfig"
        :size="12"
        class="text-primary-600 ml-1 node-detail-help-text"
        name="question"
      />
    </div>
    <div v-if="isValueTypePlain" :class="cssClass" class="mt-1 node-detail-value">
      {{ itemValue }}
    </div>
    <div v-if="isValueTypeGraph" :class="{ 'd-flex': itemValueStale }" class="mt-1">
      <stacked-progress-bar
        :css-class="itemValueStale ? 'flex-fill' : ''"
        :success-label="successLabel"
        :failure-label="failureLabel"
        :neutral-label="neutralLabel"
        :success-count="itemValue.successCount"
        :failure-count="itemValue.failureCount"
        :total-count="itemValue.totalCount"
      />
      <icon
        v-show="itemValueStale"
        v-tooltip
        :title="itemValueStaleTooltip"
        name="time-out"
        class="ml-2 text-warning-500"
        data-container="body"
      />
    </div>
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
