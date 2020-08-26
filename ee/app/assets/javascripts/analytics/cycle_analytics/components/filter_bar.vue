<script>
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';

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
    FilteredSearchBar,
    UrlSync,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('filters', {
      selectedMilestone: state => state.milestones.selected,
      selectedAuthor: state => state.authors.selected,
      selectedLabels: state => state.labels.selected,
      selectedAssignees: state => state.assignees.selected,
      milestonesData: state => state.milestones.data,
      labelsData: state => state.labels.data,
      authorsData: state => state.authors.data,
      assigneesData: state => state.assignees.data,
    }),
    tokens() {
      return [
        {
          icon: 'clock',
          title: __('Milestone'),
          type: 'milestone',
          token: MilestoneToken,
          initialMilestones: this.milestonesData,
          unique: true,
          symbol: '%',
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchMilestones: this.fetchMilestones,
        },
        {
          icon: 'labels',
          title: __('Label'),
          type: 'labels',
          token: LabelToken,
          initialLabels: this.labelsData,
          unique: false,
          symbol: '~',
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchLabels: this.fetchLabels,
        },
        {
          icon: 'pencil',
          title: __('Author'),
          type: 'author',
          token: AuthorToken,
          initialAuthors: this.authorsData,
          unique: true,
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchAuthors: this.fetchAuthors,
        },
        {
          icon: 'user',
          title: __('Assignees'),
          type: 'assignees',
          token: AuthorToken,
          initialAuthors: this.assigneesData,
          unique: false,
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchAuthors: this.fetchAssignees,
        },
      ];
    },
    query() {
      const selectedLabels = this.selectedLabels?.length ? this.selectedLabels : null;
      const selectedAssignees = this.selectedAssignees?.length ? this.selectedAssignees : null;

      return {
        milestone_title: this.selectedMilestone,
        author_username: this.selectedAuthor,
        label_name: selectedLabels,
        assignee_username: selectedAssignees,
      };
    },
  },
  methods: {
    ...mapActions('filters', [
      'setFilters',
      'fetchMilestones',
      'fetchLabels',
      'fetchAuthors',
      'fetchAssignees',
    ]),
    initialFilterValue() {
      const {
        selectedMilestone: milestone = null,
        selectedAuthor: author = null,
        selectedAssignees: assignees = [],
        selectedLabels: labels = [],
      } = this;
      return prepareTokens({ milestone, author, assignees, labels });
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
    handleFilter(filters) {
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
  <div>
    <filtered-search-bar
      class="gl-flex-grow-1"
      :namespace="groupPath"
      recent-searches-storage-key="value-stream-analytics"
      :search-input-placeholder="__('Filter results')"
      :tokens="tokens"
      :initial-filter-value="initialFilterValue()"
      @onFilter="handleFilter"
    />
    <url-sync :query="query" />
  </div>
</template>
