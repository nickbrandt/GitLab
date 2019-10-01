<script>
import { GlEmptyState } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import DateRangeDropdown from '../../shared/components/date_range_dropdown.vue';
import SummaryTable from './summary_table.vue';
import StageTable from './stage_table.vue';

export default {
  name: 'CycleAnalytics',
  components: {
    GlEmptyState,
    GroupsDropdownFilter,
    ProjectsDropdownFilter,
    DateRangeDropdown,
    SummaryTable,
    StageTable,
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
    };
  },
  computed: {
    ...mapState([
      'isLoading',
      'isLoadingStage',
      'isLoadingStageForm',
      'isEmptyStage',
      'isAddingCustomStage',
      'selectedGroup',
      'selectedProjectIds',
      'selectedStageName',
      'stages',
      'summary',
      'dataTimeframe',
      'labels',
      'currentStageEvents',
      'customStageFormEvents',
      'errorCode',
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
  },
  methods: {
    ...mapActions([
      'fetchCustomStageFormData',
      'fetchCycleAnalyticsData',
      'fetchStageData',
      'setCycleAnalyticsDataEndpoint',
      'setStageDataEndpoint',
      'setSelectedGroup',
      'setSelectedProjects',
      'setSelectedTimeframe',
      'setSelectedStageName',
      'hideCustomStageForm',
    ]),
    onGroupSelect(group) {
      this.setCycleAnalyticsDataEndpoint(group.path);
      this.setSelectedGroup(group);
      this.fetchCycleAnalyticsData();
    },
    onProjectsSelect(projects) {
      const projectIds = projects.map(value => value.id);
      this.setSelectedProjects(projectIds);
      this.fetchCycleAnalyticsData();
    },
    onTimeframeSelect(days) {
      this.setSelectedTimeframe(days);
      this.fetchCycleAnalyticsData();
    },
    onStageSelect(stage) {
      this.hideCustomStageForm();
      this.setSelectedStageName(stage.name);
      this.setStageDataEndpoint(this.currentStage.slug);
      this.fetchStageData(this.currentStage.name);
    },
    onShowAddStageForm() {
      this.fetchCustomStageFormData(this.currentGroupPath);
    },
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
          :query-params="groupsQueryParams"
          @selected="onGroupSelect"
        />
        <projects-dropdown-filter
          v-if="shouldDisplayFilters"
          :key="selectedGroup.id"
          class="js-projects-dropdown-filter ml-md-1 mt-1 mt-md-0 dropdown-select"
          :group-id="selectedGroup.id"
          :multi-select="multiProjectSelect"
          @selected="onProjectsSelect"
        />
        <div
          v-if="shouldDisplayFilters"
          class="ml-0 ml-md-auto mt-2 mt-md-0 d-flex flex-column flex-md-row align-items-md-center justify-content-md-end"
        >
          <label class="text-bold mb-0 mr-1">{{ __('Timeframe') }}</label>
          <date-range-dropdown
            class="js-timeframe-filter"
            :available-days-in-past="dateOptions"
            :default-selected="dataTimeframe"
            @selected="onTimeframeSelect"
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
        <summary-table class="js-summary-table" :items="summary" />
        <stage-table
          v-if="currentStage"
          class="js-stage-table"
          :current-stage="currentStage"
          :stages="stages"
          :is-loading="isLoadingStage || isLoadingStageForm"
          :is-empty-stage="isEmptyStage"
          :is-adding-custom-stage="isAddingCustomStage"
          :current-stage-events="currentStageEvents"
          :custom-stage-form-events="customStageFormEvents"
          :labels="labels"
          :no-data-svg-path="noDataSvgPath"
          :no-access-svg-path="noAccessSvgPath"
          :can-edit-stages="hasCustomizableCycleAnalytics"
          @selectStage="onStageSelect"
          @showAddStageForm="onShowAddStageForm"
        />
      </div>
    </div>
  </div>
</template>
