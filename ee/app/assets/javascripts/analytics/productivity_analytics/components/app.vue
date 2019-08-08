<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import {
  GlEmptyState,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import MergeRequestTable from './mr_table.vue';
import { chartKeys } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    GlButton,
    Icon,
    MergeRequestTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      chartKeys,
    };
  },
  computed: {
    ...mapState('filters', ['groupNamespace', 'projectPath']),
    ...mapState('table', [
      'isLoadingTable',
      'mergeRequests',
      'pageInfo',
      'sortFields',
      'columnMetric',
    ]),
    ...mapGetters('table', [
      'sortFieldDropdownLabel',
      'sortIcon',
      'sortTooltipTitle',
      'getColumnOptions',
      'columnMetricLabel',
    ]),
  },
  mounted() {
    this.setEndpoint(this.endpoint);
  },
  methods: {
    ...mapActions(['setEndpoint']),
    ...mapActions('filters', ['setProjectPath']),
    ...mapActions('table', [
      'setSortField',
      'setMergeRequestsPage',
      'toggleSortOrder',
      'setColumnMetric',
    ]),
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="!groupNamespace"
      class="js-empty-state"
      :title="
        __('Productivity analytics can help identify the problems that are delaying your team')
      "
      :svg-path="emptyStateSvgPath"
      :description="
        __(
          'Start by choosing a group to start exploring the merge requests in that group. You can then proceed to filter by projects, labels, milestones, authors and assignees.',
        )
      "
    />
    <template v-else>
      <div
        class="qa-mr-table-sort d-flex flex-column flex-md-row align-items-md-center justify-content-between mb-2"
      >
        <h5>{{ __('List') }}</h5>
        <div v-if="mergeRequests" class="d-flex flex-column flex-md-row align-items-md-center">
          <strong class="mr-2">{{ __('Sort by') }}</strong>
          <div class="d-flex">
            <gl-dropdown
              class="mr-2 flex-grow"
              toggle-class="dropdown-menu-toggle"
              :text="sortFieldDropdownLabel"
            >
              <gl-dropdown-item
                v-for="(value, key) in sortFields"
                :key="key"
                active-class="is-active"
                class="w-100"
                @click="setSortField(key)"
              >
                {{ value }}
              </gl-dropdown-item>
            </gl-dropdown>
            <gl-button v-gl-tooltip.hover :title="sortTooltipTitle" @click="toggleSortOrder">
              <icon :name="sortIcon" />
            </gl-button>
          </div>
        </div>
      </div>
      <div class="qa-mr-table">
        <gl-loading-icon v-if="isLoadingTable" size="md" class="my-4 py-4" />
        <merge-request-table
          v-else
          :merge-requests="mergeRequests"
          :page-info="pageInfo"
          :column-options="getColumnOptions"
          :metric-type="columnMetric"
          :metric-label="columnMetricLabel"
          @columnMetricChange="setColumnMetric"
          @pageChange="setMergeRequestsPage"
        />
      </div>
    </template>
  </div>
</template>
