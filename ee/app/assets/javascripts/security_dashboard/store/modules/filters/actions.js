import Stats from 'ee/stats';
import * as types from './mutation_types';

export const setFilter = ({ commit }, payload) => {
  commit(types.SET_FILTER, payload);

  Stats.trackEvent(document.body.dataset.page, 'set_filter', {
    label: payload.filterId,
    value: payload.optionId,
  });
};

export const setFilterOptions = ({ commit }, payload) => {
  commit(types.SET_FILTER_OPTIONS, payload);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
