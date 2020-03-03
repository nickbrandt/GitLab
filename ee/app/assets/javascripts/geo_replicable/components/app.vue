<script>
import { mapActions, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import GeoReplicableFilterBar from './geo_replicable_filter_bar.vue';
import GeoReplicable from './geo_replicable.vue';
import GeoReplicableEmptyState from './geo_replicable_empty_state.vue';

export default {
  name: 'GeoReplicableApp',
  components: {
    GlLoadingIcon,
    GeoReplicableFilterBar,
    GeoReplicable,
    GeoReplicableEmptyState,
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
    hasData() {
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
  <article class="geo-replicable-container">
    <geo-replicable-filter-bar />
    <gl-loading-icon v-if="isLoading" size="xl" />
    <template v-else>
      <geo-replicable v-if="hasData" />
      <geo-replicable-empty-state
        v-else
        :issues-svg-path="issuesSvgPath"
        :geo-troubleshooting-link="geoTroubleshootingLink"
      />
    </template>
  </article>
</template>
