<script>
import { mapState, mapActions } from 'vuex';
import { GlFilteredSearch } from '@gitlab/ui';
import { __ } from '~/locale';
import MilestoneToken from '../../shared/components/tokens/milestone_token.vue';
import LabelToken from '../../shared/components/tokens/label_token.vue';
import UserToken from '../../shared/components/tokens/user_token.vue';

export const prepareTokens = ({
  milestone = null,
  author = null,
  assignees = [],
  labels = [],
} = {}) => {
  const authorToken = author ? [{ type: 'author', value: { data: author } }] : [];
  const milestoneToken = milestone ? [{ type: 'milestone', value: { data: milestone } }] : [];
  const assigneeTokens = assignees?.length
    ? assignees.map(data => ({ type: 'assignees', value: { data } }))
    : [];
  const labelTokens = labels?.length
    ? labels.map(data => ({ type: 'labels', value: { data } }))
    : [];

  return [...authorToken, ...milestoneToken, ...assigneeTokens, ...labelTokens];
};

export default {
  name: 'FilterBar',
  components: {
    GlFilteredSearch,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      value: [],
    };
  },
  computed: {
    ...mapState('filters', {
      milestones: state => state.milestones.data,
      milestonesLoading: state => state.milestones.isLoading,
      labels: state => state.labels.data,
      labelsLoading: state => state.labels.isLoading,
      authors: state => state.authors.data,
      authorsLoading: state => state.authors.isLoading,
      assignees: state => state.assignees.data,
      assigneesLoading: state => state.assignees.isLoading,
      initialTokens: state => state.initialTokens,
    }),
    availableTokens() {
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
          operators: [{ value: '=', description: 'is', default: 'true' }],
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
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchData: this.fetchLabels,
        },
        {
          icon: 'pencil',
          title: __('Author'),
          type: 'author',
          token: UserToken,
          users: this.authors,
          unique: true,
          isLoading: this.authorsLoading,
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchData: this.fetchAuthors,
        },
        {
          icon: 'user',
          title: __('Assignees'),
          type: 'assignees',
          token: UserToken,
          users: this.assignees,
          unique: false,
          isLoading: this.assigneesLoading,
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchData: this.fetchAssignees,
        },
      ];
    },
  },

  mounted() {
    this.initializeTokens();
  },
  methods: {
    ...mapActions('filters', [
      'setFilters',
      'fetchMilestones',
      'fetchLabels',
      'fetchAuthors',
      'fetchAssignees',
    ]),
    initializeTokens() {
      const {
        selectedMilestone: milestone = null,
        selectedAuthor: author = null,
        selectedAssignees: assignees = [],
        selectedLabels: labels = [],
      } = this.initialTokens;
      const preparedTokens = prepareTokens({ milestone, author, assignees, labels });
      this.value = preparedTokens;
    },
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
      const { labels, milestone, author, assignees } = this.processFilters(filters);

      this.setFilters({
        selectedAuthor: author ? author[0].value : null,
        selectedMilestone: milestone ? milestone[0].value : null,
        selectedAssignees: assignees ? assignees.map(a => a.value) : [],
        selectedLabels: labels ? labels.map(l => l.value) : [],
      });
    },
  },
};
</script>

<template>
  <gl-filtered-search
    v-model="value"
    :disabled="disabled"
    :placeholder="__('Filter results')"
    :clear-button-title="__('Clear')"
    :close-button-title="__('Close')"
    :available-tokens="availableTokens"
    @submit="filteredSearchSubmit"
  />
</template>
