import { sprintf, __ } from '~/locale';
import { isBaseFilterOption } from './utils';

export const getFilter = state => filterId => state.filters.find(filter => filter.id === filterId);

export const getSelectedOptions = (state, getters) => filterId => {
  const filter = getters.getFilter(filterId);
  return filter.options.filter(option => filter.selection.has(option.id));
};

export const getSelectedOptionNames = (state, getters) => filterId => {
  const selectedOptions = getters.getSelectedOptions(filterId);
  const extraOptionCount = selectedOptions.length - 1;
  const firstOption = selectedOptions.map(option => option.name)[0];

  return {
    firstOption,
    extraOptionCount: extraOptionCount
      ? sprintf(__('+%{extraOptionCount} more'), { extraOptionCount })
      : '',
  };
};

/**
 * Loops through all the filters and returns all the active ones
 * stripping out base filter options.
 * @returns Object
 * e.g. { type: ['sast'], severity: ['high', 'medium'] }
 */
export const activeFilters = state => {
  const filters = state.filters.reduce((acc, filter) => {
    acc[filter.id] = [...Array.from(filter.selection)].filter(id => !isBaseFilterOption(id));
    return acc;
  }, {});
  // hide_dismissed is hardcoded as it currently is an edge-case, more info in the MR:
  // https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/15333#note_208301144
  filters.scope = state.hideDismissed ? 'dismissed' : 'all';
  return filters;
};

export const visibleFilters = ({ filters }) => filters.filter(({ hidden }) => !hidden);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-foss#52179 is merged
export default () => {};
