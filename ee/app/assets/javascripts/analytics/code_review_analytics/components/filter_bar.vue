<script>
import { mapState, mapActions } from 'vuex';
import { GlFilteredSearch, GlFilteredSearchToken } from '@gitlab/ui';
import { __ } from '~/locale';

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
    }),
    tokens() {
      return [
        {
          icon: 'clock',
          title: __('Milestone'),
          type: 'milestone',
          token: GlFilteredSearchToken,
          options: this.milestones,
          unique: true,
        },
      ];
    },
  },
  created() {
    this.fetchMilestones();
  },
  methods: {
    ...mapActions('filters', ['fetchMilestones', 'setFilters']),
    filteredSearchSubmit(filters) {
      const result = filters.reduce((acc, item) => {
        const {
          type,
          value: { data },
        } = item;

        if (!acc[type]) {
          acc[type] = [];
        }

        acc[type].push(data);
        return acc;
      }, {});

      this.setFilters({ label_name: result.label, milestone_title: result.milestone });
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
