<script>
import { s__, __ } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';

import { VALUE_TYPE } from '../../constants';

import DetailsSectionMixin from '../../mixins/details_section_mixin';

import GeoNodeDetailItem from '../geo_node_detail_item.vue';
import SectionRevealButton from './section_reveal_button.vue';

export default {
  valueType: VALUE_TYPE,
  components: {
    SectionRevealButton,
    GeoNodeDetailItem,
  },
  mixins: [DetailsSectionMixin],
  props: {
    node: {
      type: Object,
      required: true,
    },
    nodeDetails: {
      type: Object,
      required: true,
    },
    nodeTypePrimary: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      showSectionItems: false,
    };
  },
  computed: {
    nodeDetailItems() {
      if (this.nodeTypePrimary) {
        // Return primary node detail items
        const primaryNodeDetailItems = [
          {
            itemTitle: s__('GeoNodes|Replication slots'),
            itemValue: this.nodeDetails.replicationSlots,
            itemValueType: VALUE_TYPE.GRAPH,
            successLabel: s__('GeoNodes|Used slots'),
            neutraLabel: s__('GeoNodes|Unused slots'),
          },
        ];

        if (this.nodeDetails.replicationSlots.totalCount) {
          primaryNodeDetailItems.push({
            itemTitle: s__('GeoNodes|Replication slot WAL'),
            itemValue: numberToHumanSize(this.nodeDetails.replicationSlotWAL),
            itemValueType: VALUE_TYPE.PLAIN,
            cssClass: 'node-detail-value-bold',
          });
        }

        return primaryNodeDetailItems;
      }

      // Return secondary node detail items
      return [
        {
          itemTitle: s__('GeoNodes|Storage config'),
          itemValue: this.storageShardsStatus,
          itemValueType: VALUE_TYPE.PLAIN,
          cssClass: this.storageShardsCssClass,
        },
        {
          itemTitle: s__('GeoNodes|Alternate URL'),
          itemValue: this.node.alternateUrl,
          itemValueType: VALUE_TYPE.PLAIN,
          cssClass: 'node-detail-value-bold',
        },
      ];
    },
    storageShardsStatus() {
      if (this.nodeDetails.storageShardsMatch == null) {
        return __('Unknown');
      }
      return this.nodeDetails.storageShardsMatch
        ? __('OK')
        : s__('GeoNodes|Does not match the primary storage configuration');
    },
    storageShardsCssClass() {
      const cssClass = 'node-detail-value-bold';
      return !this.nodeDetails.storageShardsMatch
        ? `${cssClass} node-detail-value-error`
        : cssClass;
    },
    sectionItemsContainerClasses() {
      const { nodeTypePrimary, showSectionItems } = this;
      return {
        'col-md-6 prepend-left-15': nodeTypePrimary,
        'row col-md-12 prepend-left-10': !nodeTypePrimary,
        'd-flex': showSectionItems && !nodeTypePrimary,
      };
    },
  },
  methods: {
    handleSectionToggle(toggleState) {
      this.showSectionItems = toggleState;
    },
  },
};
</script>

<template>
  <div class="row-fluid clearfix node-detail-section other-section">
    <div class="col-md-12">
      <section-reveal-button
        :button-title="__('Other information')"
        @toggleButton="handleSectionToggle"
      />
    </div>
    <div
      v-show="showSectionItems"
      :class="sectionItemsContainerClasses"
      class="prepend-top-10 section-items-container"
    >
      <geo-node-detail-item
        v-for="(nodeDetailItem, index) in nodeDetailItems"
        :key="index"
        :class="{ 'prepend-top-15 prepend-left-10': nodeTypePrimary, 'col-sm-3': !nodeTypePrimary }"
        :css-class="nodeDetailItem.cssClass"
        :item-title="nodeDetailItem.itemTitle"
        :item-value="nodeDetailItem.itemValue"
        :item-value-type="nodeDetailItem.itemValueType"
        :item-value-stale="statusInfoStale"
        :item-value-stale-tooltip="statusInfoStaleMessage"
      />
    </div>
  </div>
</template>
