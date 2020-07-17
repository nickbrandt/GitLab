<script>
import { GlAlert, GlButton, GlLoadingIcon, GlPagination, GlTab, GlTabs } from '@gitlab/ui';
import { __ } from '~/locale';
import IterationsList from './iterations_list.vue';
import GroupIterationQuery from '../queries/group_iterations.query.graphql';

const pageSize = 20;

export default {
  components: {
    IterationsList,
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlPagination,
    GlTab,
    GlTabs,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    canAdmin: {
      type: Boolean,
      required: false,
      default: false,
    },
    newIterationPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    group: {
      query: GroupIterationQuery,
      variables() {
        return this.queryVariables;
      },
      update: data => {
        return {
          iterations: data.group?.iterations?.nodes || [],
          pageInfo: data.group?.iterations?.pageInfo || {},
        };
      },
      error() {
        this.error = __('Error loading iterations');
      },
    },
  },
  data() {
    return {
      group: {
        iterations: [],
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
        },
      },
      pagination: {
        currentPage: 1,
      },
      tabIndex: 0,
      error: '',
    };
  },
  computed: {
    queryVariables() {
      const vars = {
        fullPath: this.groupPath,
        state: this.state,
      };

      if (this.pagination.beforeCursor) {
        vars.beforeCursor = this.pagination.beforeCursor;
        vars.lastPageSize = pageSize;
      } else {
        vars.afterCursor = this.pagination.afterCursor;
        vars.firstPageSize = pageSize;
      }

      return vars;
    },
    iterations() {
      return this.group.iterations;
    },
    loading() {
      return this.$apollo.queries.group.loading;
    },
    state() {
      switch (this.tabIndex) {
        default:
        case 0:
          return 'opened';
        case 1:
          return 'closed';
        case 2:
          return 'all';
      }
    },
    prevPage() {
      return Number(this.group.pageInfo.hasPreviousPage);
    },
    nextPage() {
      return Number(this.group.pageInfo.hasNextPage);
    },
  },
  methods: {
    handlePageChange(page) {
      const { startCursor, endCursor } = this.group.pageInfo;

      if (page > this.pagination.currentPage) {
        this.pagination = {
          afterCursor: endCursor,
          currentPage: page,
        };
      } else {
        this.pagination = {
          beforeCursor: startCursor,
          currentPage: page,
        };
      }
    },
    handleTabChange() {
      this.pagination = { currentPage: 1 };
    },
  },
};
</script>

<template>
  <gl-tabs v-model="tabIndex" @activate-tab="handleTabChange">
    <gl-tab v-for="tab in [__('Open'), __('Closed'), __('All')]" :key="tab">
      <template #title>
        {{ tab }}
      </template>
      <div v-if="loading" class="gl-my-5">
        <gl-loading-icon size="lg" />
      </div>
      <div v-else-if="error">
        <gl-alert variant="danger" @dismiss="error = ''">
          {{ error }}
        </gl-alert>
      </div>
      <div v-else>
        <iterations-list :iterations="iterations" />
        <gl-pagination
          v-if="prevPage || nextPage"
          :value="pagination.currentPage"
          :prev-page="prevPage"
          :next-page="nextPage"
          align="center"
          class="gl-pagination gl-mt-3"
          @input="handlePageChange"
        />
      </div>
    </gl-tab>
    <template v-if="canAdmin" #tabs-end>
      <li class="gl-ml-auto gl-display-flex gl-align-items-center">
        <gl-button variant="success" :href="newIterationPath">{{ __('New iteration') }}</gl-button>
      </li>
    </template>
  </gl-tabs>
</template>
