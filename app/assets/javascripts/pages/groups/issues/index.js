import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import issuableInitBulkUpdateSidebar from '~/issuable_init_bulk_update_sidebar';
import { FILTERED_SEARCH } from '~/pages/constants';
import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';

document.addEventListener('DOMContentLoaded', () => {
  IssuableFilteredSearchTokenKeys.addExtraTokensForIssues();

  // FIXME: Hardcoded prefix
  issuableInitBulkUpdateSidebar.init('issue_');

  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    isGroupDecendent: true,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });
  projectSelect();
});
