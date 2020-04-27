<script>
import { GlPopover, GlLink, GlIcon, GlSprintf } from '@gitlab/ui';

import { s__ } from '~/locale';

import { VALUE_TYPE, HELP_INFO_URL } from '../../constants';

import GeoNodeDetailItem from '../geo_node_detail_item.vue';
import SectionRevealButton from './section_reveal_button.vue';

export default {
  components: {
    GlIcon,
    GlPopover,
    GlLink,
    GlSprintf,
    GeoNodeDetailItem,
    SectionRevealButton,
  },
  props: {
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
      primaryNodeDetailItems: this.getPrimaryNodeDetailItems(),
      secondaryNodeDetailItems: this.getSecondaryNodeDetailItems(),
    };
  },
  computed: {
    nodeDetailItems() {
      return this.nodeTypePrimary
        ? this.getPrimaryNodeDetailItems()
        : this.getSecondaryNodeDetailItems();
    },
    nodeText() {
      return this.nodeTypePrimary ? s__('GeoNodes|secondary nodes') : s__('GeoNodes|primary node');
    },
  },
  methods: {
    getPrimaryNodeDetailItems() {
      return [
        {
          itemTitle: s__('GeoNodes|Repository checksum progress'),
          itemValue: this.nodeDetails.repositoriesChecksummed,
          itemValueType: VALUE_TYPE.GRAPH,
          successLabel: s__('GeoNodes|Checksummed'),
          neutraLabel: s__('GeoNodes|Not checksummed'),
          failureLabel: s__('GeoNodes|Failed'),
        },
        {
          itemTitle: s__('GeoNodes|Wiki checksum progress'),
          itemValue: this.nodeDetails.wikisChecksummed,
          itemValueType: VALUE_TYPE.GRAPH,
          successLabel: s__('GeoNodes|Checksummed'),
          neutraLabel: s__('GeoNodes|Not checksummed'),
          failureLabel: s__('GeoNodes|Failed'),
        },
      ];
    },
    getSecondaryNodeDetailItems() {
      return [
        {
          itemTitle: s__('GeoNodes|Repository verification progress'),
          itemValue: this.nodeDetails.verifiedRepositories,
          itemValueType: VALUE_TYPE.GRAPH,
          successLabel: s__('GeoNodes|Verified'),
          neutraLabel: s__('GeoNodes|Unverified'),
          failureLabel: s__('GeoNodes|Failed'),
        },
        {
          itemTitle: s__('GeoNodes|Wiki verification progress'),
          itemValue: this.nodeDetails.verifiedWikis,
          itemValueType: VALUE_TYPE.GRAPH,
          successLabel: s__('GeoNodes|Verified'),
          neutraLabel: s__('GeoNodes|Unverified'),
          failureLabel: s__('GeoNodes|Failed'),
        },
      ];
    },
    handleSectionToggle(toggleState) {
      this.showSectionItems = toggleState;
    },
  },
  HELP_INFO_URL,
};
</script>

<template>
  <div class="row-fluid clearfix py-3 border-top border-color-default verification-section">
    <div class="col-md-12 d-flex align-items-center">
      <section-reveal-button
        :button-title="__('Verification information')"
        @toggleButton="handleSectionToggle"
      />
      <gl-icon
        ref="verificationInfo"
        tabindex="0"
        name="question"
        class="text-primary-600 ml-1 cursor-pointer"
      />
      <gl-popover :target="() => $refs.verificationInfo.$el" placement="top" triggers="hover focus">
        <p>
          <gl-sprintf
            :message="
              s__('GeoNodes|Replicated data is verified with the %{nodeText} using checksums')
            "
          >
            <template #nodeText>
              {{ nodeText }}
            </template>
          </gl-sprintf>
        </p>
        <gl-link class="mt-3" :href="$options.HELP_INFO_URL" target="_blank">{{
          __('More information')
        }}</gl-link>
      </gl-popover>
    </div>
    <template v-if="showSectionItems">
      <div class="col-md-6 ml-2 mt-2 section-items-container">
        <geo-node-detail-item
          v-for="(nodeDetailItem, index) in nodeDetailItems"
          :key="index"
          :css-class="nodeDetailItem.cssClass"
          :item-title="nodeDetailItem.itemTitle"
          :item-value="nodeDetailItem.itemValue"
          :item-value-type="nodeDetailItem.itemValueType"
          :success-label="nodeDetailItem.successLabel"
          :neutral-label="nodeDetailItem.neutraLabel"
          :failure-label="nodeDetailItem.failureLabel"
          :custom-type="nodeDetailItem.customType"
        />
      </div>
    </template>
  </div>
</template>
