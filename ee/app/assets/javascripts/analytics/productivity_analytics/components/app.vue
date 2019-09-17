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
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import Icon from '~/vue_shared/components/icon.vue';
import MergeRequestTable from './mr_table.vue';
import { chartKeys } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    GlColumnChart,
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
    noAccessSvgPath: {
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
    ...mapState('table', ['isLoadingTable', 'mergeRequests', 'pageInfo', 'columnMetric']),
    ...mapGetters(['getMetricTypes']),
    ...mapGetters('charts', [
      'chartLoading',
      'getChartData',
      'getColumnChartDatazoomOption',
      'getMetricDropdownLabel',
      'isSelectedMetric',
    ]),
    ...mapGetters('table', [
      'sortFieldDropdownLabel',
      'sortIcon',
      'sortTooltipTitle',
      'tableSortOptions',
      'columnMetricLabel',
      'isSelectedSortField',
      'hasNoAccessError',
    ]),
    showAppContent() {
      return this.groupNamespace && !this.hasNoAccessError;
    },
  },
  mounted() {
    this.setEndpoint(this.endpoint);
  },
  methods: {
    ...mapActions(['setEndpoint']),
    ...mapActions('filters', ['setProjectPath']),
    ...mapActions('charts', ['fetchChartData', 'setMetricType', 'chartItemClicked']),
    ...mapActions('table', [
      'setSortField',
      'setMergeRequestsPage',
      'toggleSortOrder',
      'setColumnMetric',
    ]),
    onMainChartItemClicked({ params }) {
      const itemValue = params.data.value[0];
      this.chartItemClicked({ chartKey: this.chartKeys.main, item: itemValue });
    },
    getColumnChartOption(chartKey) {
      return {
        yAxis: {
          axisLabel: {
            formatter: value => value,
          },
        },
        ...this.getColumnChartDatazoomOption(chartKey),
      };
    },
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
    <gl-empty-state
      v-if="hasNoAccessError"
      class="js-empty-state"
      :title="__('You don’t have acces to Productivity Analaytics in this group')"
      :svg-path="noAccessSvgPath"
      :description="
        __(
          'Only ‘Reporter’ roles and above on tiers Premium / Silver and above can see Productivity Analytics.',
        )
      "
    />
    <template v-if="showAppContent">
      <h4>{{ __('Merge Requests') }}</h4>
      <div class="qa-time-to-merge mb-4">
        <h5>{{ __('Time to merge') }}</h5>
        <gl-loading-icon v-if="chartLoading(chartKeys.main)" size="md" class="my-4 py-4" />
        <template v-else>
          <p class="text-muted">
            {{ __('You can filter by "days to merge" by clicking on the columns in the chart.') }}
          </p>
          <gl-column-chart
            :data="getChartData(chartKeys.main)"
            :option="getColumnChartOption(chartKeys.main)"
            :y-axis-title="__('Merge requests')"
            :x-axis-title="__('Days')"
            x-axis-type="category"
            @chartItemClicked="onMainChartItemClicked"
          />
        </template>
      </div>

      <div class="row">
        <div class="qa-time-based col-lg-6 col-sm-12 mb-4">
          <gl-dropdown
            class="mb-4 metric-dropdown"
            toggle-class="dropdown-menu-toggle w-100"
            menu-class="w-100 mw-100"
            :text="getMetricDropdownLabel(chartKeys.timeBasedHistogram)"
          >
            <gl-dropdown-item
              v-for="metric in getMetricTypes(chartKeys.timeBasedHistogram)"
              :key="metric.key"
              active-class="is-active"
              class="w-100"
              @click="
                setMetricType({ metricType: metric.key, chartKey: chartKeys.timeBasedHistogram })
              "
            >
              <span class="d-flex">
                <icon
                  class="flex-shrink-0 append-right-4"
                  :class="{
                    invisible: !isSelectedMetric({
                      metric: metric.key,
                      chartKey: chartKeys.timeBasedHistogram,
                    }),
                  }"
                  name="mobile-issue-close"
                />
                {{ metric.label }}
              </span>
            </gl-dropdown-item>
          </gl-dropdown>
          <gl-loading-icon
            v-if="chartLoading(chartKeys.timeBasedHistogram)"
            size="md"
            class="my-4 py-4"
          />
          <gl-column-chart
            v-else
            :data="getChartData(chartKeys.timeBasedHistogram)"
            :option="getColumnChartOption(chartKeys.timeBasedHistogram)"
            :y-axis-title="__('Merge requests')"
            :x-axis-title="__('Hours')"
            x-axis-type="category"
          />
        </div>

        <div class="qa-commit-based col-lg-6 col-sm-12 mb-4">
          <gl-dropdown
            class="mb-4 metric-dropdown"
            toggle-class="dropdown-menu-toggle w-100"
            menu-class="w-100 mw-100"
            :text="getMetricDropdownLabel(chartKeys.commitBasedHistogram)"
          >
            <gl-dropdown-item
              v-for="metric in getMetricTypes(chartKeys.commitBasedHistogram)"
              :key="metric.key"
              active-class="is-active"
              class="w-100"
              @click="
                setMetricType({ metricType: metric.key, chartKey: chartKeys.commitBasedHistogram })
              "
            >
              <span class="d-flex">
                <icon
                  class="flex-shrink-0 append-right-4"
                  :class="{
                    invisible: !isSelectedMetric({
                      metric: metric.key,
                      chartKey: chartKeys.commitBasedHistogram,
                    }),
                  }"
                  name="mobile-issue-close"
                />
                {{ metric.label }}
              </span>
            </gl-dropdown-item>
          </gl-dropdown>
          <gl-loading-icon
            v-if="chartLoading(chartKeys.commitBasedHistogram)"
            size="md"
            class="my-4 py-4"
          />
          <gl-column-chart
            v-else
            :data="getChartData(chartKeys.commitBasedHistogram)"
            :option="getColumnChartOption(chartKeys.commitBasedHistogram)"
            :y-axis-title="__('Merge requests')"
            :x-axis-title="__('Commits')"
            x-axis-type="category"
          />
        </div>
      </div>

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
                v-for="metric in tableSortOptions"
                :key="metric.key"
                active-class="is-active"
                class="w-100"
                @click="setSortField(metric.key)"
              >
                <span class="d-flex">
                  <icon
                    class="flex-shrink-0 append-right-4"
                    :class="{
                      invisible: !isSelectedSortField(metric.key),
                    }"
                    name="mobile-issue-close"
                  />
                  {{ metric.label }}
                </span>
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
          :column-options="getMetricTypes(chartKeys.timeBasedHistogram)"
          :metric-type="columnMetric"
          :metric-label="columnMetricLabel"
          @columnMetricChange="setColumnMetric"
          @pageChange="setMergeRequestsPage"
        />
      </div>
    </template>
  </div>
</template>
