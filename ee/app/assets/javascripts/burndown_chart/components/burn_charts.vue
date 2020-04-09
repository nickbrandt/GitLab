<script>
import { GlDeprecatedButton, GlButtonGroup } from '@gitlab/ui';
import { __ } from '~/locale';
import BurndownChart from './burndown_chart.vue';

export default {
  burnupChartsEnabled: gon.features.burnupCharts,
  components: {
    GlDeprecatedButton,
    GlButtonGroup,
    BurndownChart,
  },
  props: {
    startDate: {
      type: String,
      required: true,
    },
    dueDate: {
      type: String,
      required: true,
    },
    openIssuesCount: {
      type: Array,
      required: false,
      default: () => [],
    },
    openIssuesWeight: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      issuesSelected: true,
    };
  },
  computed: {
    title() {
      return this.$options.burnupChartsEnabled ? __('Charts') : __('Burndown chart');
    },
  },
  methods: {
    showIssueCount() {
      this.issuesSelected = true;
    },
    showIssueWeight() {
      this.issuesSelected = false;
    },
  },
};
</script>

<template>
  <div data-qa-selector="burndown_chart">
    <div class="burndown-header d-flex align-items-center">
      <h3>{{ title }}</h3>
      <gl-button-group class="ml-3 js-burndown-data-selector">
        <gl-deprecated-button
          ref="totalIssuesButton"
          :variant="issuesSelected ? 'primary' : 'inverted-primary'"
          size="sm"
          @click="showIssueCount"
        >
          {{ __('Issues') }}
        </gl-deprecated-button>
        <gl-deprecated-button
          ref="totalWeightButton"
          :variant="issuesSelected ? 'inverted-primary' : 'primary'"
          size="sm"
          data-qa-selector="weight_button"
          @click="showIssueWeight"
        >
          {{ __('Issue weight') }}
        </gl-deprecated-button>
      </gl-button-group>
    </div>
    <div v-if="$options.burnupChartsEnabled" class="row">
      <burndown-chart
        :start-date="startDate"
        :due-date="dueDate"
        :open-issues-count="openIssuesCount"
        :open-issues-weight="openIssuesWeight"
        :issues-selected="issuesSelected"
        class="col-md-6"
      />
    </div>
    <burndown-chart
      v-else
      :show-title="false"
      :start-date="startDate"
      :due-date="dueDate"
      :open-issues-count="openIssuesCount"
      :open-issues-weight="openIssuesWeight"
      :issues-selected="issuesSelected"
    />
  </div>
</template>
