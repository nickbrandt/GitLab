import Vue from 'vue';
import IssuesAnalytics from './components/issues_analytics.vue';
import store from './stores';
import FilteredSearchIssueAnalytics from './filtered_search_issues_analytics';
import { urlParamsToObject } from '~/lib/utils/common_utils';

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
  const filters = urlParamsToObject(window.location.search);
  store.dispatch('issueAnalytics/setFilters', filters);

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
