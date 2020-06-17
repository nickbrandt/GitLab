<script>
import { mapState, mapActions } from 'vuex';
import { GlPagination } from '@gitlab/ui';
import GeoReplicableItem from './geo_replicable_item.vue';

export default {
  name: 'GeoReplicable',
  components: {
    GlPagination,
    GeoReplicableItem,
  },
  computed: {
    ...mapState(['replicableItems', 'paginationData', 'useGraphQl']),
    page: {
      get() {
        return this.paginationData.page;
      },
      set(newVal) {
        this.setPage(newVal);
        this.fetchReplicableItems();
      },
    },
    showRestfulPagination() {
      return !this.useGraphQl && this.paginationData.total > 0;
    },
  },
  methods: {
    ...mapActions(['setPage', 'fetchReplicableItems']),
    buildName(item) {
      return item.name ? item.name : item.id;
    },
  },
};
</script>

<template>
  <section>
    <geo-replicable-item
      v-for="item in replicableItems"
      :key="item.id"
      :name="buildName(item)"
      :project-id="item.projectId"
      :sync-status="item.state.toLowerCase()"
      :last-synced="item.lastSyncedAt"
      :last-verified="item.lastVerifiedAt"
      :last-checked="item.lastCheckedAt"
    />
    <gl-pagination
      v-if="showRestfulPagination"
      v-model="page"
      :per-page="paginationData.perPage"
      :total-items="paginationData.total"
      align="center"
    />
  </section>
</template>
