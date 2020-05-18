<script>
import { mapState, mapActions } from 'vuex';
import { GlFilteredSearch } from '@gitlab/ui';
import { __ } from '~/locale';
import MilestoneToken from '../../shared/components/tokens/milestone_token.vue';
import LabelToken from '../../shared/components/tokens/label_token.vue';

export default {
  components: {
    GlFilteredSearch,
  },
  data() {
    return {
      searchTerms: [],
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
        },
        {
          icon: 'labels',
          title: __('Label'),
          type: 'label',
          token: LabelToken,
          labels: this.labels,
          unique: false,
          symbol: '~',
          isLoading: this.labelsLoading,
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
    processFilters(filters) {
      return filters.reduce((acc, token) => {
        const { type, value } = token;
        const { operator } = value;
        let tokenValue = value.data;

        // remove wrapping double quotes which were added for token values that include spaces
        if (
          (tokenValue[0] === "'" && tokenValue[tokenValue.length - 1] === "'") ||
          (tokenValue[0] === '"' && tokenValue[tokenValue.length - 1] === '"')
        ) {
          tokenValue = tokenValue.slice(1, -1);
        }

        if (!acc[type]) {
          acc[type] = [];
        }

        acc[type].push({ value: tokenValue, operator });
        return acc;
      }, {});
    },
    filteredSearchSubmit(filters) {
      const { label: labelNames, milestone } = this.processFilters(filters);
      const milestoneTitle = milestone ? milestone[0] : null;
      this.setFilters({ labelNames, milestoneTitle });
    },
  },
};
</script>

<template>
  <div class="bg-secondary-50 p-3 border-top border-bottom">
    <gl-filtered-search
      :v-model="searchTerms"
      :placeholder="__('Filter results')"
      :clear-button-title="__('Clear')"
      :close-button-title="__('Close')"
      :available-tokens="tokens"
      @submit="filteredSearchSubmit"
    />
  </div>
</template>
