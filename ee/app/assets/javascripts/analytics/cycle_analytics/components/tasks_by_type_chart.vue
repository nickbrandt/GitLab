<script>
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';
import { s__, sprintf } from '~/locale';
import { dateFormats } from '../../shared/constants';

const formattedDate = d => dateFormat(d, dateFormats.defaultDate);

export default {
  name: 'TasksByTypeChart',
  components: {
    GlStackedColumnChart,
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
  },
  computed: {
    hasData() {
      return this.chartData && this.chartData.data && this.chartData.data.length;
    },
    selectedFiltersText() {
      const { subject, selectedLabelIds } = this.filters;
      return sprintf(
        s__('CycleAnalyticsCharts|Showing %{subject} and %{selectedLabelsCount} labels'),
        {
          subject,
          selectedLabelsCount: selectedLabelIds.length,
        },
      );
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
              "CycleAnalyticsCharts|Showing data for group '%{groupName}' and %{selectedProjectCount} projects from %{startDate} to %{endDate}",
            )
          : s__(
              "CycleAnalyticsCharts|Showing data for group '%{groupName}' from %{startDate} to %{endDate}",
            );
      return sprintf(str, {
        startDate: formattedDate(startDate),
        endDate: formattedDate(endDate),
        groupName,
        selectedProjectCount,
      });
    },
  },
  chartOptions: {
    legend: false,
  },
};
</script>
<template>
  <div>
    <div class="row">
      <div class="col-12">
        <h3>{{ __('Type of work') }}</h3>
        <div v-if="hasData">
          <p>{{ summaryDescription }}</p>
          <h4>{{ __('Tasks by type') }}</h4>
          <p>{{ selectedFiltersText }}</p>
          <gl-stacked-column-chart
            :option="$options.chartOptions"
            :data="chartData.data"
            :group-by="chartData.groupBy"
            x-axis-type="category"
            x-axis-title="Date"
            y-axis-title="Number of tasks"
            :series-names="chartData.seriesNames"
          />
        </div>
        <div v-else class="bs-callout bs-callout-info">
          <p>{{ __('There is no data available. Please change your selection.') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
