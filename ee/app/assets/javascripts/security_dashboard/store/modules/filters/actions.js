import Tracking from '~/tracking';
import { getParameterValues } from '~/lib/utils/url_utility';
import * as types from './mutation_types';

export const setFilter = ({ commit }, payload) => {
  commit(types.SET_FILTER, payload);

  Tracking.event(document.body.dataset.page, 'set_filter', {
    label: payload.filterId,
    value: payload.optionId,
  });
};

export const setFilterOptions = ({ commit }, payload) => {
  commit(types.SET_FILTER_OPTIONS, payload);
};

export const setAllFilters = ({ commit }, payload) => {
  commit(types.SET_ALL_FILTERS, payload);
};

export const lockFilter = ({ commit }, payload) => {
  commit(types.SET_FILTER, payload);
  commit(types.HIDE_FILTER, payload);
};

export const setHideDismissedToggleInitialState = ({ commit }) => {
  const [urlParam] = getParameterValues('scope');
  const showDismissed = urlParam === 'all';
  commit(types.SET_TOGGLE_VALUE, { key: 'hideDismissed', value: !showDismissed });
};

export const setToggleValue = ({ commit }, { key, value }) => {
  commit(types.SET_TOGGLE_VALUE, { key, value });

  Tracking.event(document.body.dataset.page, 'set_toggle', {
    label: key,
    value,
  });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-foss#52179 is merged
export default () => {};
