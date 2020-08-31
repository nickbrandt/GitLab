<script>
import { mapState, mapActions } from 'vuex';
import { __ } from '~/locale';
import MilestoneToken from '../../shared/components/tokens/milestone_token.vue';
import LabelToken from '../../shared/components/tokens/label_token.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
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
      milestonesLoading: state => state.milestones.isLoading,
      labelsLoading: state => state.labels.isLoading,
      selectedMilestone: state => state.milestones.selected,
      selectedLabelList: state => state.labels.selectedList,
      milestonesData: state => state.milestones.data,
      labelsData: state => state.labels.data,
    }),
    tokens() {
      return [
        {
          icon: 'clock',
          title: __('Milestone'),
          type: 'milestone',
          token: MilestoneToken,
          milestones: this.milestonesData,
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
          labels: this.labelsData,
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
    ...mapActions('filters', ['setFilters', 'fetchMilestones', 'fetchLabels']),
    handleFilter(filters) {
      const { labels, milestone } = processFilters(filters);

      this.setFilters({
        selectedMilestone: milestone ? milestone[0] : null,
        selectedLabelList: labels,
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
