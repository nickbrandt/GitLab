<script>
import { GlButton, GlButtonGroup } from '@gitlab/ui';
import { __ } from '~/locale';
import BurndownChart from './burndown_chart.vue';

export default {
  components: {
    GlButton,
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
      burnupChartsEnabled: gon.features.burnupCharts,
    };
  },
  computed: {
    title() {
      return this.burnupChartsEnabled ? __('Charts') : __('Burndown chart');
    },
    issueButtonCategory() {
      return this.issuesSelected ? 'primary' : 'secondary';
    },
    weightButtonCategory() {
      return this.issuesSelected ? 'secondary' : 'primary';
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
      <h3 ref="chartsTitle">{{ title }}</h3>
      <gl-button-group class="ml-3 js-burndown-data-selector">
        <gl-button
          ref="totalIssuesButton"
          :category="issueButtonCategory"
          variant="info"
          size="small"
          @click="showIssueCount"
        >
          {{ __('Issues') }}
        </gl-button>
        <gl-button
          ref="totalWeightButton"
          :category="weightButtonCategory"
          variant="info"
          size="small"
          data-qa-selector="weight_button"
          @click="showIssueWeight"
        >
          {{ __('Issue weight') }}
        </gl-button>
      </gl-button-group>
    </div>
    <div v-if="burnupChartsEnabled" class="row">
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
