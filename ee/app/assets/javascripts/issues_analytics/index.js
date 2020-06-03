import Vue from 'vue';
import IssuesAnalytics from './components/issues_analytics.vue';
import store from './stores';
import FilteredSearchIssueAnalytics from './filtered_search_issues_analytics';

export default () => {
  const el = document.querySelector('#js-issues-analytics');
  const filterBlockEl = document.querySelector('.issues-filters');

  if (!el) return null;

  const {
    endpoint,
    noDataEmptyStateSvgPath,
    filtersEmptyStateSvgPath,
    issuesApiEndpoint,
    issuesPageEndpoint,
  } = el.dataset;

  // Set default filters from URL
  store.dispatch('issueAnalytics/setFilters', window.location.search);

  return new Vue({
    el,
    store,
    components: {
      IssuesAnalytics,
    },
    mounted() {
      this.filterManager = new FilteredSearchIssueAnalytics(store.state.issueAnalytics.filters);
      this.filterManager.setup();
    },
    render(createElement) {
      return createElement('issues-analytics', {
        props: {
          endpoint,
          filterBlockEl,
          noDataEmptyStateSvgPath,
          filtersEmptyStateSvgPath,
          issuesApiEndpoint,
          issuesPageEndpoint,
        },
      });
    },
  });
};
