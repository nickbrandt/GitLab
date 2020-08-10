<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import throughputChartQueryBuilder from '../graphql/throughput_chart_query_builder';
import { DEFAULT_NUMBER_OF_DAYS, THROUGHPUT_STRINGS } from '../constants';

export default {
  name: 'ThroughputChart',
  components: {
    GlAreaChart,
    GlAlert,
    GlLoadingIcon,
  },
  inject: ['fullPath'],
  data() {
    return {
      throughputChartData: [],
      startDate: getDateInPast(new Date(), DEFAULT_NUMBER_OF_DAYS),
      endDate: new Date(),
    };
  },
  apollo: {
    throughputChartData: {
      query() {
        return throughputChartQueryBuilder(this.startDate, this.endDate);
      },
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
    },
  },
  computed: {
    chartOptions() {
      return {
        xAxis: {
          name: THROUGHPUT_STRINGS.X_AXIS_TITLE,
          type: 'category',
          axisLabel: {
            formatter: value => {
              return value.split('_')[0]; // Aug_2020 => Aug
            },
          },
        },
        yAxis: {
          name: THROUGHPUT_STRINGS.Y_AXIS_TITLE,
        },
      };
    },
    formattedThroughputChartData() {
      const data = Object.keys(this.throughputChartData)
        .slice(0, -1) // Remove the __typeName key
        .map(value => [value, this.throughputChartData[value].count]);

      return [
        {
          name: THROUGHPUT_STRINGS.Y_AXIS_TITLE,
          data,
        },
      ];
    },
    chartDataLoading() {
      return this.$apollo.queries.throughputChartData.loading;
    },
    chartDataAvailable() {
      return this.formattedThroughputChartData[0].data.length;
    },
  },
  strings: {
    chartTitle: THROUGHPUT_STRINGS.CHART_TITLE,
    chartDescription: THROUGHPUT_STRINGS.CHART_DESCRIPTION,
    noData: THROUGHPUT_STRINGS.NO_DATA,
  },
};
</script>
<template>
  <div>
    <h4 data-testid="chartTitle">{{ $options.strings.chartTitle }}</h4>
    <div class="gl-text-gray-700" data-testid="chartDescription">
      {{ $options.strings.chartDescription }}
    </div>
    <gl-loading-icon v-if="chartDataLoading" size="md" class="gl-mt-4" />
    <gl-area-chart
      v-else-if="chartDataAvailable"
      :data="formattedThroughputChartData"
      :option="chartOptions"
    />
    <gl-alert v-else :dismissible="false" class="gl-mt-4">{{ $options.strings.noData }}</gl-alert>
  </div>
</template>
