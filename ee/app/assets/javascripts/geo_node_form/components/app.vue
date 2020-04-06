<script>
import { __ } from '~/locale';
import GeoNodeForm from './geo_node_form.vue';

export default {
  name: 'GeoNodeFormApp',
  components: {
    GeoNodeForm,
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
    pageTitle() {
      return this.node ? __('Edit Geo Node') : __('New Geo Node');
    },
  },
};
</script>

<template>
  <article class="geo-node-form-container">
    <h3 class="page-title">{{ pageTitle }}</h3>
    <geo-node-form v-bind="$props" />
  </article>
</template>
