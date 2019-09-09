import Tracking from '~/tracking';
import { getParameterValues } from '~/lib/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';
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
  const [urlParam] = getParameterValues('hide_dismissed');
  if (typeof urlParam !== 'undefined') {
    const parsedParam = parseBoolean(urlParam);
    commit(types.SET_TOGGLE_VALUE, { key: 'hide_dismissed', value: parsedParam });
  }
};

export const setToggleValue = ({ commit }, { key, value }) => {
  commit(types.SET_TOGGLE_VALUE, { key, value });

  Tracking.event(document.body.dataset.page, 'set_toggle', {
    label: key,
    value,
  });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
