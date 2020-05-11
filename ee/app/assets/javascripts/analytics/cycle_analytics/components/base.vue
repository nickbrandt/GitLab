<script>
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PROJECTS_PER_PAGE, STAGE_ACTIONS } from '../constants';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import { LAST_ACTIVITY_AT, DATE_RANGE_LIMIT } from '../../shared/constants';
import DateRange from '../../shared/components/daterange.vue';
import StageTable from './stage_table.vue';
import DurationChart from './duration_chart.vue';
import TypeOfWorkCharts from './type_of_work_charts.vue';
import UrlSyncMixin from '../../shared/mixins/url_sync_mixin';
import { toYmd } from '../../shared/utils';
import RecentActivityCard from './recent_activity_card.vue';
import StageTableNav from './stage_table_nav.vue';
import CustomStageForm from './custom_stage_form.vue';

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
    TypeOfWorkCharts,
    RecentActivityCard,
    CustomStageForm,
    StageTableNav,
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
      'isEmptyStage',
      'selectedGroup',
      'selectedProjects',
      'selectedStage',
      'stages',
      'summary',
      'currentStageEvents',
      'errorCode',
      'startDate',
      'endDate',
      'medians',
    ]),
    ...mapState('customStages', [
      'isSavingCustomStage',
      'isCreatingCustomStage',
      'isEditingCustomStage',
      'formEvents',
      'formErrors',
      'formInitialData',
    ]),
    ...mapGetters([
      'hasNoAccessError',
      'currentGroupPath',
      'activeStages',
      'selectedProjectIds',
      'enableCustomOrdering',
      'cycleAnalyticsRequestParams',
    ]),
    ...mapGetters('customStages', ['customStageFormActive']),
    shouldRenderEmptyState() {
      return !this.selectedGroup;
    },
    shouldDisplayFilters() {
      return this.selectedGroup && !this.errorCode;
    },
    shouldDisplayDurationChart() {
      return this.featureFlags.hasDurationChart && !this.hasNoAccessError && !this.isLoading;
    },
    shouldDisplayTypeOfWorkCharts() {
      return !this.hasNoAccessError && !this.isLoading;
    },
    isLoadingTypeOfWork() {
      return this.isLoadingTasksByTypeChartTopLabels || this.isLoadingTasksByTypeChart;
    },
    isUpdatingCustomStage() {
      return this.isEditingCustomStage && this.isSavingCustomStage;
    },
    hasDateRangeSet() {
      return this.startDate && this.endDate;
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
    });
  },
  methods: {
    ...mapActions([
      'fetchCycleAnalyticsData',
      'fetchStageData',
      'setSelectedGroup',
      'setSelectedProjects',
      'setSelectedStage',
      'setDateRange',
      'updateStage',
      'removeStage',
      'setFeatureFlags',
      'updateStage',
      'reorderStage',
    ]),
    ...mapActions('customStages', [
      'hideForm',
      'showCreateForm',
      'showEditForm',
      'createStage',
      'clearFormErrors',
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
      this.hideForm();
      this.setSelectedStage(stage);
      this.fetchStageData(this.selectedStage.slug);
    },
    onShowAddStageForm() {
      this.showCreateForm();
    },
    onShowEditStageForm(initData = {}) {
      this.showEditForm(initData);
    },
    onCreateCustomStage(data) {
      this.createStage(data);
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
  STAGE_ACTIONS,
};
</script>
<template>
  <div>
    <div class="mb-3">
      <h3>{{ __('Value Stream Analytics') }}</h3>
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
            :is-loading="isLoadingStage"
            :is-empty-stage="isEmptyStage"
            :custom-stage-form-active="customStageFormActive"
            :current-stage-events="currentStageEvents"
            :no-data-svg-path="noDataSvgPath"
          >
            <template #nav>
              <stage-table-nav
                :current-stage="selectedStage"
                :stages="activeStages"
                :medians="medians"
                :is-creating-custom-stage="isCreatingCustomStage"
                :custom-stage-form-active="customStageFormActive"
                :can-edit-stages="true"
                :custom-ordering="enableCustomOrdering"
                @reorderStage="onStageReorder"
                @selectStage="onStageSelect"
                @editStage="onShowEditStageForm"
                @showAddStageForm="onShowAddStageForm"
                @hideStage="onUpdateCustomStage"
                @removeStage="onRemoveStage"
              />
            </template>
            <template v-if="customStageFormActive" #content>
              <gl-loading-icon v-if="isUpdatingCustomStage" class="mt-4" size="md" />
              <custom-stage-form
                v-else
                :events="formEvents"
                :is-saving-custom-stage="isSavingCustomStage"
                :initial-fields="formInitialData"
                :is-editing-custom-stage="isEditingCustomStage"
                :errors="formErrors"
                @createStage="onCreateCustomStage"
                @updateStage="onUpdateCustomStage"
                @clearErrors="$emit('clearFormErrors')"
              />
            </template>
          </stage-table>
        </div>
      </div>
      <duration-chart v-if="shouldDisplayDurationChart" class="mt-3" :stages="activeStages" />
      <type-of-work-charts v-if="shouldDisplayTypeOfWorkCharts" :is-loading="isLoadingTypeOfWork" />
    </div>
  </div>
</template>
