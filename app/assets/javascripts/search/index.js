import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import { queryToObject } from '~/lib/utils/url_utility';
import Project from '~/pages/projects/project';
import { initSidebar } from './sidebar';
import { initSearchSort } from './sort';
import createStore from './store';
import { initTopbar } from './topbar';

export const initSearchApp = () => {
  // Similar to url_utility.decodeUrlParameter
  // Our query treats + as %20.  This replaces the query + symbols with %20.
  const sanitizedSearch = window.location.search.replace(/\+/g, '%20');
  const query = queryToObject(sanitizedSearch);

  const store = createStore({ query });

  initTopbar(store);
  initSidebar(store);
  initSearchSort(store);

  setHighlightClass(query.search); // Code Highlighting
  Project.initRefSwitcher(); // Code Search Branch Picker
};
