<script>
import { mapActions, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import GeoDesignsFilterBar from './geo_designs_filter_bar.vue';
import GeoDesigns from './geo_designs.vue';
import GeoDesignsEmptyState from './geo_designs_empty_state.vue';

export default {
  name: 'GeoDesignsApp',
  components: {
    GlLoadingIcon,
    GeoDesignsFilterBar,
    GeoDesigns,
    GeoDesignsEmptyState,
  },
  props: {
    geoSvgPath: {
      type: String,
      required: true,
    },
    issuesSvgPath: {
      type: String,
      required: true,
    },
    geoTroubleshootingLink: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['isLoading', 'totalReplicableItems']),
    hasReplicableItems() {
      return this.totalReplicableItems > 0;
    },
  },
  created() {
    this.fetchReplicableItems();
  },
  methods: {
    ...mapActions(['fetchReplicableItems']),
  },
};
</script>

<template>
  <article class="geo-designs-container">
    <geo-designs-filter-bar />
    <gl-loading-icon v-if="isLoading" size="xl" />
    <template v-else>
      <geo-designs v-if="hasReplicableItems" />
      <geo-designs-empty-state
        v-else
        :issues-svg-path="issuesSvgPath"
        :geo-troubleshooting-link="geoTroubleshootingLink"
      />
    </template>
  </article>
</template>
