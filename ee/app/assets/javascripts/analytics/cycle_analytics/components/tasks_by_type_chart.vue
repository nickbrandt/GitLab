<script>
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { s__, sprintf } from '~/locale';
import { formattedDate } from '../../shared/utils';
import { TASKS_BY_TYPE_SUBJECT_ISSUE } from '../constants';
import TasksByTypeFilters from './tasks_by_type_filters.vue';

export default {
  name: 'TasksByTypeChart',
  components: {
    GlStackedColumnChart,
    TasksByTypeFilters,
  },
  props: {
    filters: {
      type: Object,
      required: true,
    },
    chartData: {
      type: Object,
      required: true,
    },
    labels: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasData() {
      return Boolean(this.chartData?.data?.length);
    },
    summaryDescription() {
      const {
        startDate,
        endDate,
        selectedProjectIds,
        selectedGroup: { name: groupName },
      } = this.filters;

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
        filters: { subject },
      } = this;
      return subject || TASKS_BY_TYPE_SUBJECT_ISSUE;
    },
  },
};
</script>
<template>
  <div class="row">
    <div class="col-12">
      <h3>{{ s__('CycleAnalytics|Type of work') }}</h3>
      <div v-if="hasData">
        <p>{{ summaryDescription }}</p>
        <tasks-by-type-filters
          :labels="labels"
          :selected-label-ids="filters.selectedLabelIds"
          :subject-filter="selectedSubjectFilter"
          @updateFilter="$emit('updateFilter', $event)"
        />
        <gl-stacked-column-chart
          :data="chartData.data"
          :group-by="chartData.groupBy"
          x-axis-type="category"
          y-axis-type="value"
          :x-axis-title="__('Date')"
          :y-axis-title="s__('CycleAnalytics|Number of tasks')"
          :series-names="chartData.seriesNames"
        />
      </div>
      <div v-else class="bs-callout bs-callout-info">
        <p>{{ __('There is no data available. Please change your selection.') }}</p>
      </div>
    </div>
  </div>
</template>
