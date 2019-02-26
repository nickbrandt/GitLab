import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import FilteredSearchManager from '~/filtered_search/filtered_search_manager';
import { historyPushState } from '~/lib/utils/common_utils';
import issueAnalyticsStore from './stores';

export default class FilteredSearchIssueAnalytics extends FilteredSearchManager {
  constructor() {
    super({
      page: 'issues_analytics',
      isGroupDecendent: true,
      stateFiltersSelector: '.issues-state-filters',
      isGroup: true,
      filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
    });

    this.isHandledAsync = true;
  }

  /**
   * Updates issues analytics store and window history
   * with filter path
   */
  updateObject = path => {
    historyPushState(path);
    issueAnalyticsStore.dispatch('issueAnalytics/setFilters', path);
  };
}
