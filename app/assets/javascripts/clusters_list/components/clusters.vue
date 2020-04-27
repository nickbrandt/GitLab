<script>
import { mapState, mapActions } from 'vuex';
import { GlBadge, GlLink, GlLoadingIcon, GlPagination, GlTable, GlTooltip, GlTooltipDirective } from '@gitlab/ui';
import { CLUSTER_TYPES, STATUSES } from '../constants';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlTable,
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  fields: [
    {
      key: 'name',
      label: __('Kubernetes cluster'),
    },
    {
      key: 'environmentScope',
      label: __('Environment scope'),
    },
    //{
    //  key: 'size',
    //  label: __('Size'),
    //},
    //{
    //  key: 'cpu',
    //  label: __('Total cores (vCPUs)'),
    //},
    //{
    //  key: 'memory',
    //  label: __('Total memory (GB)'),
    //},
    {
      key: 'clusterType',
      label: __('Cluster level'),
      formatter: value => CLUSTER_TYPES[value],
    },
  ],
  computed: {
    ...mapState(['clusters', 'clustersPerPage', 'currentPage', 'loading', 'totalPages']),
  },
  mounted() {
    this.fetchClusters();
  },
  methods: {
    ...mapActions(['fetchClusters', 'updateCurrentPage']),
    queryClusterGroup(page) {
      this.updateCurrentPage(page)
      // this.fetchClusters(page);
    }
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading" size="md" class="mt-3" />
  <section v-else>
    <gl-table
      :items="clusters"
      :fields="$options.fields"
      stacked="md"
      variant="light"
      class="qa-clusters-table"
    >
      <template #cell(name)="{item}">
        <div>
          <gl-link
            data-qa-selector="cluster"
            :data-qa-cluster-name="item.name"
            :href="item.path"
          >
            {{ item.name }}
          </gl-link>

          <gl-loading-icon
            :id="`cluster-loading-${item.name}`"
            size="sm"
            v-gl-tooltip.hover="{ container: `cluster-loading-${item.name}` }"
            v-if="item.status == 'creating'"
            :title="__('Cluster is being created')"
          />

          <gl-badge
            v-if="!item.enabled"
            variant="danger"
          >
            {{ __('Connection disabled') }}
          </gl-badge>
        </div>
      </template>

      <template #cell(clusterType)="{value}">
        <gl-badge variant="light">
          {{ value }}
        </gl-badge>
      </template>
    </gl-table>

    <gl-pagination
      v-model="currentPage"
      :per-page="clustersPerPage"
      :total-items="totalPages"
      :prev-text="__('Prev')"
      :next-text="__('Next')"
      @input="queryClusterGroup"
      class="justify-content-center"
    />
  </section>
</template>
