<script>
import { GlEmptyState, GlDaterangePicker, GlLoadingIcon } from '@gitlab/ui';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { mapActions, mapState, mapGetters } from 'vuex';
import dateFormat from 'dateformat';
import { s__, sprintf } from '~/locale';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { prepareLabelDatasetForChart, generateDatesInRange } from '../utils';
import { PROJECTS_PER_PAGE, DEFAULT_DAYS_IN_PAST } from '../constants';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import Scatterplot from '../../shared/components/scatterplot.vue';
import StageDropdownFilter from './stage_dropdown_filter.vue';
import SummaryTable from './summary_table.vue';
import StageTable from './stage_table.vue';
import { LAST_ACTIVITY_AT, dateFormats } from '../../shared/constants';

export default {
  name: 'CycleAnalytics',
  components: {
    GlLoadingIcon,
    GlEmptyState,
    GlStackedColumnChart,
    GroupsDropdownFilter,
    ProjectsDropdownFilter,
    SummaryTable,
    StageTable,
    GlDaterangePicker,
    StageDropdownFilter,
    Scatterplot,
  },
  mixins: [glFeatureFlagsMixin()],
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
  },
  data() {
    return {
      multiProjectSelect: true,
      dateOptions: [7, 30, 90],
      groupsQueryParams: {
        min_access_level: featureAccessLevel.EVERYONE,
      },
      projectsQueryParams: {
        per_page: PROJECTS_PER_PAGE,
        with_shared: false,
        order_by: 'last_activity_at',
      },
    };
  },
  computed: {
    ...mapState([
      'featureFlags',
      'isLoading',
      'isLoadingStage',
      'isLoadingTasksByTypeChart',
      'isLoadingDurationChart',
      'isEmptyStage',
      'isSavingCustomStage',
      'isCreatingCustomStage',
      'isEditingCustomStage',
      'selectedGroup',
      'selectedStage',
      'stages',
      'summary',
      'labels',
      'currentStageEvents',
      'customStageFormEvents',
      'errorCode',
      'startDate',
      'endDate',
      'tasksByType',
      'medians',
    ]),
    ...mapGetters(['hasNoAccessError', 'currentGroupPath', 'durationChartPlottableData']),
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
      return !this.isLoadingDurationChart && !this.isLoading;
    },
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.setDateRange({
          startDate,
          endDate,
        });
      },
    },
    hasDateRangeSet() {
      return this.startDate && this.endDate;
    },
    typeOfWork() {
      // generate settings for the tasksByType chart
      // if (!this.hasDateRangeSet) {
      //   return { option: { legend: false }, datatset: [], range: [] };
      // }

      // const range = generateDatesInRange(this.startDate, this.endDate).reverse();

      // // TODO: diff and data should be replaced with the tasksByTypeData getter
      // const diff = range.length + 1;
      // const rawData = typeOfWork(diff);

      // const { data, seriesNames } = prepareLabelDatasetForChart({
      //   dataset: Object.values(rawData),
      //   range,
      // });

      return {
        option: { legend: false },
        range: [],
        data: [],
        seriesNames: [],
      };
    },
    chartDataDescription() {
      if (this.selectedGroup) {
        const selectedProjectCount = this.setSelectedProjects.length;
        const { startDate, endDate } = this;
        const { name: groupName } = this.selectedGroup;
        const str =
          selectedProjectCount > 0
            ? s__(
                "CycleAnalyticsCharts|Showing data for group '%{groupName}' and %{selectedProjectCount} projects from %{startDate} to %{endDate}",
              )
            : s__(
                "CycleAnalyticsCharts|Showing data for group '%{groupName}' from %{startDate} to %{endDate}",
              );
        return sprintf(str, {
          startDate: dateFormat(startDate, dateFormats.defaultDate),
          endDate: dateFormat(endDate, dateFormats.defaultDate),
          groupName,
          selectedProjectCount,
        });
      }
      return null;
    },
  },
  mounted() {
    // console.log('this.tasksByType', this.tasksByType);
    this.initDateRange();
    this.setFeatureFlags({
      hasDurationChart: this.glFeatures.cycleAnalyticsScatterplotEnabled,
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
      'setDateRange',
      'fetchTasksByTypeData',
      'updateSelectedDurationChartStages',
      'createCustomStage',
      'updateStage',
      'removeStage',
      'setFeatureFlags',
      'editCustomStage',
      'updateStage',
    ]),
    onGroupSelect(group) {
      this.setSelectedGroup(group);
      this.fetchCycleAnalyticsData();
    },
    onProjectsSelect(projects) {
      const projectIds = projects.map(value => value.id);
      this.setSelectedProjects(projectIds);
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
      this.editCustomStage(initData);
    },
    initDateRange() {
      const endDate = new Date(Date.now());
      const startDate = getDateInPast(endDate, DEFAULT_DAYS_IN_PAST);
      this.setDateRange({ skipFetch: true, startDate, endDate });
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
    onDurationStageSelect(stages) {
      this.updateSelectedDurationChartStages(stages);
    },
  },
  groupsQueryParams: {
    min_access_level: featureAccessLevel.EVERYONE,
  },
  projectsQueryParams: {
    per_page: PROJECTS_PER_PAGE,
    with_shared: false,
    order_by: LAST_ACTIVITY_AT,
  },
};
</script>

<template>
  <div>
    <div class="page-title-holder d-flex align-items-center">
      <h3 class="page-title">{{ __('Cycle Analytics') }}</h3>
    </div>
    <div class="mw-100">
      <div
        class="mt-3 py-2 px-3 d-flex bg-gray-light border-top border-bottom flex-column flex-md-row justify-content-between"
      >
        <groups-dropdown-filter
          class="js-groups-dropdown-filter dropdown-select"
          :query-params="$options.groupsQueryParams"
          @selected="onGroupSelect"
        />
        <projects-dropdown-filter
          v-if="shouldDisplayFilters"
          :key="selectedGroup.id"
          class="js-projects-dropdown-filter ml-md-1 mt-1 mt-md-0 dropdown-select"
          :group-id="selectedGroup.id"
          :query-params="$options.projectsQueryParams"
          :multi-select="multiProjectSelect"
          @selected="onProjectsSelect"
        />
        <div
          v-if="shouldDisplayFilters"
          class="ml-0 ml-md-auto mt-2 mt-md-0 d-flex flex-column flex-md-row align-items-md-center justify-content-md-end"
        >
          <gl-daterange-picker
            v-model="dateRange"
            class="d-flex flex-column flex-lg-row js-daterange-picker"
            :default-start-date="startDate"
            :default-end-date="endDate"
            start-picker-class="d-flex flex-column flex-lg-row align-items-lg-center mr-lg-2"
            end-picker-class="d-flex flex-column flex-lg-row align-items-lg-center"
            theme="animate-picker"
          />
        </div>
      </div>
    </div>
    <gl-empty-state
      v-if="shouldRenderEmptyState"
      :title="__('Cycle Analytics can help you determine your team’s velocity')"
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
        :title="__('You don’t have access to Cycle Analytics for this group')"
        :svg-path="noAccessSvgPath"
        :description="
          __(
            'Only \'Reporter\' roles and above on tiers Premium / Silver and above can see Cycle Analytics.',
          )
        "
      />
      <div v-else-if="!errorCode">
        <div v-if="isLoading">
          <gl-loading-icon class="mt-4" size="md" />
        </div>
        <div v-else>
          <summary-table class="js-summary-table" :items="summary" />
          <stage-table
            v-if="selectedStage"
            class="js-stage-table"
            :current-stage="selectedStage"
            :stages="stages"
            :medians="medians"
            :is-loading="isLoadingStage"
            :is-empty-stage="isEmptyStage"
            :is-saving-custom-stage="isSavingCustomStage"
            :is-creating-custom-stage="isCreatingCustomStage"
            :is-editing-custom-stage="isEditingCustomStage"
            :current-stage-events="currentStageEvents"
            :custom-stage-form-events="customStageFormEvents"
            :labels="labels"
            :no-data-svg-path="noDataSvgPath"
            :no-access-svg-path="noAccessSvgPath"
            :can-edit-stages="hasCustomizableCycleAnalytics"
            @selectStage="onStageSelect"
            @editStage="onShowEditStageForm"
            @showAddStageForm="onShowAddStageForm"
            @hideStage="onUpdateCustomStage"
            @removeStage="onRemoveStage"
            @createStage="onCreateCustomStage"
            @updateStage="onUpdateCustomStage"
          />
        </div>
      </div>
      <template v-if="featureFlags.hasDurationChart">
        <template v-if="shouldDisplayDurationChart">
          <div class="mt-3 d-flex">
            <h4 class="mt-0">{{ s__('CycleAnalytics|Days to completion') }}</h4>
            <stage-dropdown-filter
              v-if="stages.length"
              class="ml-auto"
              :stages="stages"
              @selected="onDurationStageSelect"
            />
          </div>
          <scatterplot
            v-if="durationChartPlottableData"
            :x-axis-title="s__('CycleAnalytics|Date')"
            :y-axis-title="s__('CycleAnalytics|Total days to completion')"
            :scatter-data="durationChartPlottableData"
          />
          <div v-else ref="duration-chart-no-data" class="bs-callout bs-callout-info">
            {{ __('There is no data available. Please change your selection.') }}
          </div>
        </template>
        <gl-loading-icon v-else-if="!isLoading" size="md" class="my-4 py-4" />
      </template>
    </div>
    <div v-if="hasDateRangeSet">
      <!-- TODO: move into component file -->
      <div class="row">
        <div class="col-12">
          <h2>{{ __('Type of work') }}</h2>
          <p>{{ __('Showing data for __ groups and __ projects from __ to __') }}</p>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <header>
            <h3>{{ __('Tasks by type') }}</h3>
          </header>
          <section>
            <gl-stacked-column-chart
              :option="typeOfWork.option"
              :data="typeOfWork.data"
              :group-by="typeOfWork.range"
              x-axis-type="category"
              x-axis-title="Date"
              y-axis-title="Number of tasks"
              :series-names="typeOfWork.seriesNames"
            />
          </section>
        </div>
      </div>
    </div>
  </div>
</template>
