<script>
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PROJECTS_PER_PAGE } from '../constants';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import { LAST_ACTIVITY_AT, DATE_RANGE_LIMIT } from '../../shared/constants';
import DateRange from '../../shared/components/daterange.vue';
import StageTable from './stage_table.vue';
import DurationChart from './duration_chart.vue';
import TasksByTypeChart from './tasks_by_type_chart.vue';
import UrlSyncMixin from '../../shared/mixins/url_sync_mixin';
import { toYmd } from '../../shared/utils';
import RecentActivityCard from './recent_activity_card.vue';

export default {
  name: 'CycleAnalytics',
  components: {
    DateRange,
    DurationChart,
    GlLoadingIcon,
    GlEmptyState,
    GroupsDropdownFilter,
    ProjectsDropdownFilter,
    StageTable,
    TasksByTypeChart,
    RecentActivityCard,
  },
  mixins: [glFeatureFlagsMixin(), UrlSyncMixin],
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    noDataSvgPath: {
      type: String,
      required: true,
    },
    noAccessSvgPath: {
      type: String,
      required: true,
    },
    hideGroupDropDown: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'featureFlags',
      'isLoading',
      'isLoadingStage',
      'isLoadingTasksByTypeChart',
      'isEmptyStage',
      'isSavingCustomStage',
      'isCreatingCustomStage',
      'isEditingCustomStage',
      'selectedGroup',
      'selectedProjects',
      'selectedStage',
      'stages',
      'summary',
      'topRankedLabels',
      'currentStageEvents',
      'customStageFormEvents',
      'errorCode',
      'startDate',
      'endDate',
      'tasksByType',
      'medians',
      'customStageFormErrors',
    ]),
    ...mapGetters([
      'hasNoAccessError',
      'currentGroupPath',
      'tasksByTypeChartData',
      'activeStages',
      'selectedProjectIds',
      'enableCustomOrdering',
      'cycleAnalyticsRequestParams',
    ]),
    shouldRenderEmptyState() {
      return !this.selectedGroup;
    },
    hasCustomizableCycleAnalytics() {
      return Boolean(this.glFeatures.customizableCycleAnalytics);
    },
    shouldDisplayFilters() {
      return this.selectedGroup && !this.errorCode;
    },
    shouldDisplayDurationChart() {
      return this.featureFlags.hasDurationChart && !this.hasNoAccessError && !this.isLoading;
    },
    shouldDisplayTasksByTypeChart() {
      return this.featureFlags.hasTasksByTypeChart && !this.hasNoAccessError;
    },
    isTasksByTypeChartLoaded() {
      return !this.isLoading && !this.isLoadingTasksByTypeChart;
    },
    hasDateRangeSet() {
      return this.startDate && this.endDate;
    },
    selectedTasksByTypeFilters() {
      const {
        selectedGroup,
        startDate,
        endDate,
        selectedProjectIds,
        tasksByType: { subject, selectedLabelIds },
      } = this;
      return {
        selectedGroup,
        selectedProjectIds,
        startDate,
        endDate,
        subject,
        selectedLabelIds,
      };
    },
    query() {
      return {
        group_id: !this.hideGroupDropDown ? this.currentGroupPath : null,
        'project_ids[]': this.selectedProjectIds,
        created_after: toYmd(this.startDate),
        created_before: toYmd(this.endDate),
      };
    },
    stageCount() {
      return this.activeStages.length;
    },
  },
  mounted() {
    this.setFeatureFlags({
      hasDurationChart: this.glFeatures.cycleAnalyticsScatterplotEnabled,
      hasDurationChartMedian: this.glFeatures.cycleAnalyticsScatterplotMedianEnabled,
      hasTasksByTypeChart: this.glFeatures.tasksByTypeChart,
    });
  },
  methods: {
    ...mapActions([
      'fetchCycleAnalyticsData',
      'fetchStageData',
      'setSelectedGroup',
      'setSelectedProjects',
      'setSelectedStage',
      'hideCustomStageForm',
      'showCustomStageForm',
      'showEditCustomStageForm',
      'setDateRange',
      'fetchTasksByTypeData',
      'createCustomStage',
      'updateStage',
      'removeStage',
      'setFeatureFlags',
      'clearCustomStageFormErrors',
      'updateStage',
      'setTasksByTypeFilters',
      'reorderStage',
    ]),
    onGroupSelect(group) {
      this.setSelectedGroup(group);
      this.fetchCycleAnalyticsData();
    },
    onProjectsSelect(projects) {
      this.setSelectedProjects(projects);
      this.fetchCycleAnalyticsData();
    },
    onStageSelect(stage) {
      this.hideCustomStageForm();
      this.setSelectedStage(stage);
      this.fetchStageData(this.selectedStage.slug);
    },
    onShowAddStageForm() {
      this.showCustomStageForm();
    },
    onShowEditStageForm(initData = {}) {
      this.showEditCustomStageForm(initData);
    },
    onCreateCustomStage(data) {
      this.createCustomStage(data);
    },
    onUpdateCustomStage(data) {
      this.updateStage(data);
    },
    onRemoveStage(id) {
      this.removeStage(id);
    },
    onStageReorder(data) {
      this.reorderStage(data);
    },
  },
  multiProjectSelect: true,
  dateOptions: [7, 30, 90],
  groupsQueryParams: {
    min_access_level: featureAccessLevel.EVERYONE,
  },
  projectsQueryParams: {
    per_page: PROJECTS_PER_PAGE,
    with_shared: false,
    order_by: LAST_ACTIVITY_AT,
    include_subgroups: true,
  },
  maxDateRange: DATE_RANGE_LIMIT,
};
</script>
<template>
  <div class="js-cycle-analytics">
    <div class="page-title-holder d-flex align-items-center">
      <h3 class="page-title">{{ __('Value Stream Analytics') }}</h3>
    </div>
    <div class="mw-100">
      <div
        class="mt-3 py-2 px-3 d-flex bg-gray-light border-top border-bottom flex-column flex-md-row justify-content-between"
      >
        <groups-dropdown-filter
          v-if="!hideGroupDropDown"
          class="js-groups-dropdown-filter dropdown-select"
          :query-params="$options.groupsQueryParams"
          :default-group="selectedGroup"
          @selected="onGroupSelect"
        />
        <projects-dropdown-filter
          v-if="shouldDisplayFilters"
          :key="selectedGroup.id"
          class="js-projects-dropdown-filter ml-md-1 mt-1 mt-md-0 dropdown-select"
          :group-id="selectedGroup.id"
          :query-params="$options.projectsQueryParams"
          :multi-select="$options.multiProjectSelect"
          :default-projects="selectedProjects"
          @selected="onProjectsSelect"
        />
        <div
          v-if="shouldDisplayFilters"
          class="ml-0 ml-md-auto mt-2 mt-md-0 d-flex flex-column flex-md-row align-items-md-center justify-content-md-end"
        >
          <date-range
            :start-date="startDate"
            :end-date="endDate"
            :max-date-range="$options.maxDateRange"
            :include-selected-date="true"
            class="js-daterange-picker"
            @change="setDateRange"
          />
        </div>
      </div>
    </div>
    <gl-empty-state
      v-if="shouldRenderEmptyState"
      :title="__('Value Stream Analytics can help you determine your team’s velocity')"
      :description="
        __(
          'Start by choosing a group to see how your team is spending time. You can then drill down to the project level.',
        )
      "
      :svg-path="emptyStateSvgPath"
    />
    <div v-else class="cycle-analytics mt-0">
      <gl-empty-state
        v-if="hasNoAccessError"
        class="js-empty-state"
        :title="__('You don’t have access to Value Stream Analytics for this group')"
        :svg-path="noAccessSvgPath"
        :description="
          __(
            'Only \'Reporter\' roles and above on tiers Premium / Silver and above can see Value Stream Analytics.',
          )
        "
      />
      <div v-else-if="!errorCode">
        <div class="js-recent-activity mt-3">
          <recent-activity-card
            :group-path="currentGroupPath"
            :additional-params="cycleAnalyticsRequestParams"
          />
        </div>
        <div v-if="isLoading">
          <gl-loading-icon class="mt-4" size="md" />
        </div>
        <div v-else>
          <stage-table
            v-if="selectedStage"
            :key="stageCount"
            class="js-stage-table"
            :current-stage="selectedStage"
            :stages="activeStages"
            :medians="medians"
            :is-loading="isLoadingStage"
            :is-empty-stage="isEmptyStage"
            :is-saving-custom-stage="isSavingCustomStage"
            :is-creating-custom-stage="isCreatingCustomStage"
            :is-editing-custom-stage="isEditingCustomStage"
            :current-stage-events="currentStageEvents"
            :custom-stage-form-events="customStageFormEvents"
            :custom-stage-form-errors="customStageFormErrors"
            :no-data-svg-path="noDataSvgPath"
            :no-access-svg-path="noAccessSvgPath"
            :can-edit-stages="hasCustomizableCycleAnalytics"
            :custom-ordering="enableCustomOrdering"
            @clearCustomStageFormErrors="clearCustomStageFormErrors"
            @selectStage="onStageSelect"
            @editStage="onShowEditStageForm"
            @showAddStageForm="onShowAddStageForm"
            @hideStage="onUpdateCustomStage"
            @removeStage="onRemoveStage"
            @createStage="onCreateCustomStage"
            @updateStage="onUpdateCustomStage"
            @reorderStage="onStageReorder"
          />
        </div>
      </div>
      <div v-if="shouldDisplayDurationChart" class="mt-3">
        <duration-chart :stages="activeStages" />
      </div>
      <template v-if="shouldDisplayTasksByTypeChart">
        <div class="js-tasks-by-type-chart">
          <div v-if="isTasksByTypeChartLoaded">
            <tasks-by-type-chart
              :chart-data="tasksByTypeChartData"
              :filters="selectedTasksByTypeFilters"
              @updateFilter="setTasksByTypeFilters"
            />
          </div>
          <gl-loading-icon v-else size="md" class="my-4 py-4" />
        </div>
      </template>
    </div>
  </div>
</template>
