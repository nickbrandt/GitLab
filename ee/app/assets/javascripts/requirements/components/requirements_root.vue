<script>
import * as Sentry from '@sentry/browser';
import { GlPagination } from '@gitlab/ui';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { urlParamsToObject } from '~/lib/utils/common_utils';
import { updateHistory, setUrlParams } from '~/lib/utils/url_utility';

import RequirementsLoading from './requirements_loading.vue';
import RequirementsEmptyState from './requirements_empty_state.vue';
import RequirementItem from './requirement_item.vue';
import projectRequirements from '../queries/projectRequirements.query.graphql';

import { FilterState, DEFAULT_PAGE_SIZE } from '../constants';

export default {
  DEFAULT_PAGE_SIZE,
  components: {
    GlPagination,
    RequirementsLoading,
    RequirementsEmptyState,
    RequirementItem,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    filterBy: {
      type: String,
      required: true,
    },
    requirementsCount: {
      type: Object,
      required: true,
      validator: value => ['OPENED', 'ARCHIVED', 'ALL'].every(prop => value[prop]),
    },
    page: {
      type: Number,
      required: false,
      default: 1,
    },
    prev: {
      type: String,
      required: false,
      default: '',
    },
    next: {
      type: String,
      required: false,
      default: '',
    },
    showCreateRequirement: {
      type: Boolean,
      required: true,
    },
    emptyStatePath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    requirements: {
      query: projectRequirements,
      variables() {
        const queryVariables = {
          projectPath: this.projectPath,
        };

        if (this.prevPageCursor) {
          queryVariables.prevPageCursor = this.prevPageCursor;
          queryVariables.lastPageSize = DEFAULT_PAGE_SIZE;
        } else if (this.nextPageCursor) {
          queryVariables.nextPageCursor = this.nextPageCursor;
          queryVariables.firstPageSize = DEFAULT_PAGE_SIZE;
        } else {
          queryVariables.firstPageSize = DEFAULT_PAGE_SIZE;
        }

        if (this.filterBy !== FilterState.all) {
          queryVariables.state = this.filterBy;
        }

        return queryVariables;
      },
      update(data) {
        const requirementsRoot = data.project?.requirements;
        const count = data.project?.requirementStatesCount;

        return {
          list: requirementsRoot?.nodes || [],
          pageInfo: requirementsRoot?.pageInfo || {},
          count: {
            OPENED: count.opened,
            ARCHIVED: count.archived,
            ALL: count.opened + count.archived,
          },
        };
      },
      error: e => {
        createFlash(__('Something went wrong while fetching requirements list.'));
        Sentry.captureException(e);
      },
    },
  },
  data() {
    return {
      currentPage: this.page,
      prevPageCursor: this.prev,
      nextPageCursor: this.next,
      requirements: {
        list: [],
        count: {},
        pageInfo: {},
      },
    };
  },
  computed: {
    requirementsListLoading() {
      return this.$apollo.queries.requirements.loading;
    },
    requirementsListEmpty() {
      return !this.$apollo.queries.requirements.loading && !this.requirements.list.length;
    },
    totalRequirements() {
      return this.requirements.count[this.filterBy] || this.requirementsCount[this.filterBy];
    },
    showPaginationControls() {
      return this.totalRequirements > DEFAULT_PAGE_SIZE && !this.requirementsListEmpty;
    },
    prevPage() {
      return Math.max(this.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.currentPage + 1;
      return nextPage > Math.ceil(this.totalRequirements / DEFAULT_PAGE_SIZE) ? null : nextPage;
    },
  },
  methods: {
    /**
     * Update browser URL with updated query-param values
     * based on current page details.
     */
    updateUrl({ page, prev, next }) {
      const { href, search } = window.location;
      const queryParams = urlParamsToObject(search);

      queryParams.page = page || 1;
      // Only keep params that have any values.
      if (prev) {
        queryParams.prev = prev;
      } else {
        delete queryParams.prev;
      }
      if (next) {
        queryParams.next = next;
      } else {
        delete queryParams.next;
      }

      // We want to replace the history state so that back button
      // correctly reloads the page with previous URL.
      updateHistory({
        url: setUrlParams(queryParams, href, true),
        title: document.title,
        replace: true,
      });
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.requirements.pageInfo;

      if (page > this.currentPage) {
        this.prevPageCursor = '';
        this.nextPageCursor = endCursor;
      } else {
        this.prevPageCursor = startCursor;
        this.nextPageCursor = '';
      }

      this.currentPage = page;

      this.updateUrl({
        page,
        prev: this.prevPageCursor,
        next: this.nextPageCursor,
      });
    },
  },
};
</script>

<template>
  <div class="requirements-list-container">
    <requirements-empty-state
      v-if="requirementsListEmpty"
      :filter-by="filterBy"
      :empty-state-path="emptyStatePath"
    />
    <requirements-loading
      v-show="requirementsListLoading"
      :filter-by="filterBy"
      :current-tab-count="totalRequirements"
      :current-page="currentPage"
    />
    <ul
      v-if="!requirementsListLoading && !requirementsListEmpty"
      class="content-list issuable-list issues-list requirements-list"
    >
      <requirement-item
        v-for="requirement in requirements.list"
        :key="requirement.iid"
        :requirement="requirement"
      />
    </ul>
    <gl-pagination
      v-if="showPaginationControls"
      :value="currentPage"
      :per-page="$options.DEFAULT_PAGE_SIZE"
      :prev-page="prevPage"
      :next-page="nextPage"
      align="center"
      class="gl-pagination prepend-top-default"
      @input="handlePageChange"
    />
  </div>
</template>
