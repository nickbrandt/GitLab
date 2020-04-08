<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { dateFormats } from '../../shared/constants';
import Scatterplot from '../../shared/components/scatterplot.vue';
import StageDropdownFilter from './stage_dropdown_filter.vue';

export default {
  name: 'DurationChart',
  components: {
    GlLoadingIcon,
    Scatterplot,
    StageDropdownFilter,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    stages: {
      type: Array,
      required: true,
    },
    scatterData: {
      type: Array,
      required: true,
    },
    medianLineData: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasData() {
      return Boolean(this.scatterData.length);
    },
  },
  methods: {
    onSelectStage(selectedStages) {
      this.$emit('stageSelected', selectedStages);
    },
  },
  durationChartTooltipDateFormat: dateFormats.defaultDate,
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="md" class="my-4 py-4" />
  <div v-else>
    <div class="d-flex">
      <h4 class="mt-0">{{ s__('CycleAnalytics|Days to completion') }}</h4>
      <stage-dropdown-filter
        v-if="stages.length"
        class="ml-auto"
        :stages="stages"
        @selected="onSelectStage"
      />
    </div>
    <scatterplot
      v-if="hasData"
      :x-axis-title="s__('CycleAnalytics|Date')"
      :y-axis-title="s__('CycleAnalytics|Total days to completion')"
      :tooltip-date-format="$options.durationChartTooltipDateFormat"
      :scatter-data="scatterData"
      :median-line-data="medianLineData"
    />
    <div v-else ref="duration-chart-no-data" class="bs-callout bs-callout-info">
      {{ __('There is no data available. Please change your selection.') }}
    </div>
  </div>
</template>
