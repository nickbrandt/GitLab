<script>
import { mapState, mapActions } from 'vuex';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { __ } from '~/locale';
import MilestoneToken from '../../shared/components/tokens/milestone_token.vue';
import LabelToken from '../../shared/components/tokens/label_token.vue';
import { processFilters } from '../../shared/utils';

export default {
  components: {
    FilteredSearchBar,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      initialFilterValue: [],
    };
  },
  computed: {
    ...mapState('filters', {
      milestonePath: 'milestonePath',
      labelsPath: 'labelsPath',
      milestones: state => state.milestones.data,
      milestonesLoading: state => state.milestones.isLoading,
      labels: state => state.labels.data,
      labelsLoading: state => state.labels.isLoading,
    }),
    tokens() {
      return [
        {
          icon: 'clock',
          title: __('Milestone'),
          type: 'milestone',
          token: MilestoneToken,
          milestones: this.milestones,
          unique: true,
          symbol: '%',
          isLoading: this.milestonesLoading,
          fetchData: this.fetchMilestones,
        },
        {
          icon: 'labels',
          title: __('Label'),
          type: 'labels',
          token: LabelToken,
          labels: this.labels,
          unique: false,
          symbol: '~',
          isLoading: this.labelsLoading,
          fetchData: this.fetchLabels,
        },
      ];
    },
  },
  created() {
    this.fetchMilestones();
    this.fetchLabels();
  },
  methods: {
    ...mapActions('filters', ['fetchMilestones', 'fetchLabels', 'setFilters']),
    handleFilter(filters) {
      const { labels, milestone } = processFilters(filters);

      this.setFilters({
        selectedMilestone: milestone ? milestone[0] : null,
        selectedLabels: labels,
      });
    },
  },
};
</script>

<template>
  <filtered-search-bar
    :namespace="projectPath"
    recent-searches-storage-key="code-review-analytics"
    :search-input-placeholder="__('Filter results')"
    :tokens="tokens"
    :initial-filter-value="initialFilterValue"
    class="row-content-block"
    @onFilter="handleFilter"
  />
</template>
