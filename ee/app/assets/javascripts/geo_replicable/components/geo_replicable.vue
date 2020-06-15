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
    ...mapState(['replicableItems', 'paginationData']),
    page: {
      get() {
        return this.paginationData.page;
      },
      set(newVal) {
        this.setPage(newVal);
        this.fetchReplicableItems();
      },
    },
    hasReplicableItems() {
      return this.paginationData.total > 0;
    },
  },
  methods: {
    ...mapActions(['setPage', 'fetchReplicableItems']),
  },
};
</script>

<template>
  <section>
    <geo-replicable-item
      v-for="item in replicableItems"
      :key="item.id"
      :name="item.name"
      :project-id="item.projectId"
      :sync-status="item.state"
      :last-synced="item.lastSyncedAt"
      :last-verified="item.lastVerifiedAt"
      :last-checked="item.lastCheckedAt"
    />
    <gl-pagination
      v-if="hasReplicableItems"
      v-model="page"
      :per-page="paginationData.perPage"
      :total-items="paginationData.total"
      align="center"
    />
  </section>
</template>
