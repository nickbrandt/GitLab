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
    ...mapState(['replicableItems', 'currentPage', 'pageSize', 'totalReplicableItems']),
    page: {
      get() {
        return this.currentPage;
      },
      set(newVal) {
        this.setPage(newVal);
        this.fetchReplicableItems();
      },
    },
    hasData() {
      return this.totalReplicableItems > 0;
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
      v-if="hasData"
      v-model="page"
      :per-page="pageSize"
      :total-items="totalReplicableItems"
      align="center"
    />
  </section>
</template>
