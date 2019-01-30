import Cookies from 'js-cookie';
import { parseBoolean } from '~/lib/utils/common_utils';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import FilteredSearchTokenKeysEpics from 'ee/filtered_search/filtered_search_token_keys_epics';
import initNewEpic from 'ee/epics/new_epic/new_epic_bundle';
import initEpicCreateApp from 'ee/epic/epic_bundle';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: 'epics',
    isGroup: true,
    isGroupDecendent: true,
    filteredSearchTokenKeys: FilteredSearchTokenKeysEpics,
    stateFiltersSelector: '.epics-state-filters',
  });

  if (parseBoolean(Cookies.get('load_new_epic_app'))) {
    initEpicCreateApp(true);
  } else {
    initNewEpic();
  }
});
