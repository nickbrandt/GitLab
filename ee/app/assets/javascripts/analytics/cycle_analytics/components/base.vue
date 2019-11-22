<script>
import { GlEmptyState, GlDaterangePicker, GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PROJECTS_PER_PAGE, DEFAULT_DAYS_IN_PAST } from '../constants';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import SummaryTable from './summary_table.vue';
import StageTable from './stage_table.vue';
import { LAST_ACTIVITY_AT } from '../../shared/constants';

export default {
  name: 'CycleAnalytics',
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GroupsDropdownFilter,
    ProjectsDropdownFilter,
    SummaryTable,
    StageTable,
    GlDaterangePicker,
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
    };
  },
  computed: {
    ...mapState([
      'isLoading',
      'isLoadingStage',
      'isLoadingChartData',
      'isEmptyStage',
      'isAddingCustomStage',
      'isSavingCustomStage',
      'selectedGroup',
      'selectedProjectIds',
      'selectedStageId',
      'stages',
      'summary',
      'labels',
      'currentStageEvents',
      'customStageFormEvents',
      'errorCode',
      'startDate',
      'endDate',
      'tasksByType',
    ]),
    ...mapGetters(['currentStage', 'defaultStage', 'hasNoAccessError', 'currentGroupPath']),
    shouldRenderEmptyState() {
      return !this.selectedGroup;
    },
    hasCustomizableCycleAnalytics() {
      return Boolean(this.glFeatures.customizableCycleAnalytics);
    },
    shouldDisplayFilters() {
      return this.selectedGroup && !this.errorCode;
    },
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.setDateRange({ startDate, endDate });
      },
    },
  },
  mounted() {
    this.initDateRange();
  },
  methods: {
    ...mapActions([
      'fetchCustomStageFormData',
      'fetchCycleAnalyticsData',
      'fetchStageData',
      'fetchGroupStagesAndEvents',
      'setSelectedGroup',
      'setSelectedProjects',
      'setSelectedTimeframe',
      'fetchStageData',
      'setSelectedStageId',
      'hideCustomStageForm',
      'showCustomStageForm',
      'setDateRange',
      'fetchTasksByTypeData',
      'createCustomStage',
      'updateStage',
      'removeStage',
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
      this.setSelectedStageId(stage.id);
      this.fetchStageData(this.currentStage.slug);
    },
    onShowAddStageForm() {
      this.showCustomStageForm();
    },
    initDateRange() {
      const endDate = new Date(Date.now());
      const startDate = getDateInPast(endDate, DEFAULT_DAYS_IN_PAST);
      this.setDateRange({ skipFetch: true, startDate, endDate });
    },
    onCreateCustomStage(data) {
      this.createCustomStage(data);
    },
    onUpdateStage(data) {
      this.updateStage(data);
    },
    onRemoveStage(id) {
      this.removeStage(id);
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
            v-if="currentStage"
            class="js-stage-table"
            :current-stage="currentStage"
            :stages="stages"
            :is-loading="isLoadingStage"
            :is-empty-stage="isEmptyStage"
            :is-adding-custom-stage="isAddingCustomStage"
            :is-saving-custom-stage="isSavingCustomStage"
            :current-stage-events="currentStageEvents"
            :custom-stage-form-events="customStageFormEvents"
            :labels="labels"
            :no-data-svg-path="noDataSvgPath"
            :no-access-svg-path="noAccessSvgPath"
            :can-edit-stages="hasCustomizableCycleAnalytics"
            @selectStage="onStageSelect"
            @showAddStageForm="onShowAddStageForm"
            @submit="onCreateCustomStage"
            @hideStage="onUpdateStage"
            @removeStage="onRemoveStage"
          />
        </div>
      </div>
    </div>
  </div>
</template>
