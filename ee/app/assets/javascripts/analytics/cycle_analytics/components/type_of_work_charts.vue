<script>
import { GlLoadingIcon } from '@gitlab/ui';
import TasksByTypeChart from './tasks_by_type/tasks_by_type_chart.vue';
import TasksByTypeFilters from './tasks_by_type/tasks_by_type_filters.vue';
import { s__, sprintf } from '~/locale';
import { formattedDate } from '../../shared/utils';
import { TASKS_BY_TYPE_SUBJECT_ISSUE } from '../constants';

export default {
  name: 'TypeOfWorkCharts',
  components: { GlLoadingIcon, TasksByTypeChart, TasksByTypeFilters },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    tasksByTypeChartData: {
      type: Object,
      required: true,
    },
    selectedTasksByTypeFilters: {
      type: Object,
      required: true,
    },
  },
  computed: {
    summaryDescription() {
      const {
        startDate,
        endDate,
        selectedProjectIds,
        selectedGroup: { name: groupName },
      } = this.selectedTasksByTypeFilters;

      const selectedProjectCount = selectedProjectIds.length;
      const str =
        selectedProjectCount > 0
          ? s__(
              "CycleAnalytics|Showing data for group '%{groupName}' and %{selectedProjectCount} projects from %{startDate} to %{endDate}",
            )
          : s__(
              "CycleAnalytics|Showing data for group '%{groupName}' from %{startDate} to %{endDate}",
            );
      return sprintf(str, {
        startDate: formattedDate(startDate),
        endDate: formattedDate(endDate),
        groupName,
        selectedProjectCount,
      });
    },
    selectedSubjectFilter() {
      const {
        selectedTasksByTypeFilters: { subject },
      } = this;
      return subject || TASKS_BY_TYPE_SUBJECT_ISSUE;
    },
  },
};
</script>
<template>
  <div class="js-tasks-by-type-chart row">
    <gl-loading-icon v-if="isLoading" size="md" class="col-12 my-4 py-4" />
    <div v-else class="col-12">
      <h3>{{ s__('CycleAnalytics|Type of work') }}</h3>
      <p>{{ summaryDescription }}</p>
      <tasks-by-type-filters
        :selected-label-ids="selectedTasksByTypeFilters.selectedLabelIds"
        :subject-filter="selectedSubjectFilter"
        @updateFilter="$emit('updateFilter', $event)"
      />
      <tasks-by-type-chart
        :data="tasksByTypeChartData.data"
        :group-by="tasksByTypeChartData.groupBy"
        :series-names="tasksByTypeChartData.seriesNames"
      />
    </div>
  </div>
</template>
