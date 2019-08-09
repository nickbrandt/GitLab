import Tracking from '~/tracking';
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

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
