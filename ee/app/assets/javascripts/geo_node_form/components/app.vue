<script>
import { GlDeprecatedBadge as GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import GeoNodeForm from './geo_node_form.vue';

export default {
  name: 'GeoNodeFormApp',
  components: {
    GeoNodeForm,
    GlBadge,
  },
  props: {
    selectiveSyncTypes: {
      type: Object,
      required: true,
    },
    syncShardsOptions: {
      type: Array,
      required: true,
    },
    node: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    isNodePrimary() {
      return this.node && this.node.primary;
    },
    pageTitle() {
      return this.node ? __('Edit Geo Node') : __('New Geo Node');
    },
    pillDetails() {
      return {
        variant: this.isNodePrimary ? 'primary' : 'light',
        label: this.isNodePrimary ? __('Primary') : __('Secondary'),
      };
    },
  },
};
</script>

<template>
  <article class="geo-node-form-container">
    <div class="gl-display-flex gl-align-items-center">
      <h3 class="page-title">{{ pageTitle }}</h3>
      <gl-badge
        class="rounded-pill gl-font-sm gl-px-3 gl-py-2 gl-ml-3"
        :variant="pillDetails.variant"
        >{{ pillDetails.label }}</gl-badge
      >
    </div>
    <geo-node-form v-bind="$props" />
  </article>
</template>
