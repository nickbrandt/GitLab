<script>
import { mapState, mapActions } from 'vuex';
import { GlPagination } from '@gitlab/ui';
import GeoDesign from './geo_design.vue';

export default {
  name: 'GeoDesigns',
  components: {
    GlPagination,
    GeoDesign,
  },
  computed: {
    ...mapState(['designs', 'currentPage', 'pageSize', 'totalDesigns']),
    page: {
      get() {
        return this.currentPage;
      },
      set(newVal) {
        this.setPage(newVal);
        this.fetchDesigns();
      },
    },
    hasDesigns() {
      return this.totalDesigns > 0;
    },
  },
  methods: {
    ...mapActions(['setPage', 'fetchDesigns']),
  },
};
</script>

<template>
  <section>
    <geo-design
      v-for="design in designs"
      :key="design.id"
      :name="design.name"
      :project-id="design.projectId"
      :sync-status="design.state"
      :last-synced="design.lastSyncedAt"
      :last-verified="design.lastVerifiedAt"
      :last-checked="design.lastCheckedAt"
    />
    <gl-pagination
      v-if="hasDesigns"
      v-model="page"
      :per-page="pageSize"
      :total-items="totalDesigns"
      align="center"
    />
  </section>
</template>
