<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlBadge, GlLoadingIcon, GlPagination } from '@gitlab/ui';
import MergeRequestTable from './merge_request_table.vue';

export default {
  components: {
    GlBadge,
    GlLoadingIcon,
    GlPagination,
    MergeRequestTable,
  },
  props: {
    projectId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapState({
      isLoading: 'isLoading',
      perPage: state => state.pageInfo.perPage,
      totalItems: state => state.pageInfo.total,
      page: state => state.pageInfo.page,
    }),
    ...mapGetters(['showMrCount']),
    currentPage: {
      get() {
        return this.page;
      },
      set(newVal) {
        this.setPage(newVal);
        this.fetchMergeRequests();
      },
    },
  },
  created() {
    this.setProjectId(this.projectId);
    this.fetchMergeRequests();
  },
  methods: {
    ...mapActions(['setProjectId', 'fetchMergeRequests', 'setPage']),
  },
};
</script>

<template>
  <div class="mt-2">
    <div>
      <span class="font-weight-bold">{{ __('Merge Requests in Review') }}</span>
      <gl-badge v-show="showMrCount" pill>{{ totalItems }}</gl-badge>
    </div>
    <gl-loading-icon v-show="isLoading" size="md" class="mt-3" />
    <template v-if="!isLoading">
      <merge-request-table />
      <gl-pagination
        v-model="currentPage"
        :per-page="perPage"
        :total-items="totalItems"
        align="center"
        class="w-100"
      />
    </template>
  </div>
</template>
