<script>
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import {
  DEFAULT_LABEL_NONE,
  DEFAULT_LABEL_ANY,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  prepareTokens,
  processFilters,
  filterToQueryObject,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

export default {
  name: 'FilterBar',
  components: {
    FilteredSearchBar,
    UrlSync,
  },
  inject: ['fullPath', 'type'],
  computed: {
    ...mapState('filters', {
      selectedMilestone: state => state.milestones.selected,
      selectedAuthor: state => state.authors.selected,
      selectedLabelList: state => state.labels.selectedList,
      selectedAssignee: state => state.assignees.selected,
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
          defaultLabels: [DEFAULT_LABEL_NONE, DEFAULT_LABEL_ANY],
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
          defaultAuthors: [],
          initialAuthors: this.authorsData,
          unique: true,
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchAuthors: this.fetchAuthors,
        },
        {
          icon: 'user',
          title: __('Assignee'),
          type: 'assignee',
          token: AuthorToken,
          defaultAuthors: [],
          initialAuthors: this.assigneesData,
          unique: false,
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchAuthors: this.fetchAssignees,
        },
      ];
    },
    query() {
      return filterToQueryObject({
        milestone_title: this.selectedMilestone,
        label_name: this.selectedLabelList,
        author_username: this.selectedAuthor,
        assignee_username: this.selectedAssignee,
      });
    },
    initialFilterValue() {
      return prepareTokens({
        milestone: this.selectedMilestone,
        author: this.selectedAuthor,
        assignee: this.selectedAssignee,
        labels: this.selectedLabelList,
      });
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
    handleFilter(filters) {
      const { labels, milestone, author, assignee } = processFilters(filters);

      this.setFilters({
        selectedAuthor: author ? author[0] : null,
        selectedMilestone: milestone ? milestone[0] : null,
        selectedAssignee: assignee ? assignee[0] : null,
        selectedLabelList: labels || [],
      });
    },
  },
};
</script>

<template>
  <div>
    <filtered-search-bar
      class="gl-flex-grow-1"
      :namespace="fullPath"
      recent-searches-storage-key="merge-request-analytics"
      :search-input-placeholder="__('Filter results')"
      :tokens="tokens"
      :initial-filter-value="initialFilterValue"
      @onFilter="handleFilter"
    />
    <url-sync :query="query" />
  </div>
</template>
