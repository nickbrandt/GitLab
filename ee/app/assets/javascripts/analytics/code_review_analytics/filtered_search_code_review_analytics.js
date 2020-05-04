import CodeReviewAnalyticsFilteredSearchTokenKeys from './code_review_analytics_filtered_search_token_keys';
import FilteredSearchManager from 'ee_else_ce/filtered_search/filtered_search_manager';
import { urlParamsToObject } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import store from './store';

export default class FilteredSearchCodeReviewAnalytics extends FilteredSearchManager {
  constructor() {
    super({
      page: 'code_reviews',
      isGroupDecendent: true,
      stateFiltersSelector: '.issues-state-filters',
      isGroup: true,
      filteredSearchTokenKeys: CodeReviewAnalyticsFilteredSearchTokenKeys,
      placeholder: __('Filter results...'),
    });

    this.isHandledAsync = true;
  }

  /**
   * Updates filters in code review analytics store
   */
  updateObject = path => {
    const filters = urlParamsToObject(path);
    store.dispatch('filters/setFilters', filters);
  };
}
