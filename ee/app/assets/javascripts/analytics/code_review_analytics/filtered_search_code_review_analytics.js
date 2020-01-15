import CodeReviewAnalyticsFilteredSearchTokenKeys from './code_review_analytics_filtered_search_token_keys';
import FilteredSearchManager from '~/filtered_search/filtered_search_manager';
import { urlParamsToObject } from '~/lib/utils/common_utils';
import createStore from './store';

export default class FilteredSearchCodeReviewAnalytics extends FilteredSearchManager {
  constructor() {
    super({
      page: 'code_reviews',
      isGroupDecendent: true,
      stateFiltersSelector: '.issues-state-filters',
      isGroup: true,
      filteredSearchTokenKeys: CodeReviewAnalyticsFilteredSearchTokenKeys,
    });

    this.isHandledAsync = true;
  }

  /**
   * Updates filters in code review analytics store
   */
  updateObject = path => {
    const filters = urlParamsToObject(path);
    const store = createStore();
    store.dispatch('setFilters', filters);
  };
}
