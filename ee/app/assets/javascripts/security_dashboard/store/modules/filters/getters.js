import { sprintf, __ } from '~/locale';

export const getFilter = state => filterId => state.filters.find(filter => filter.id === filterId);

export const getSelectedOptions = (state, getters) => filterId => {
  const filter = getters.getFilter(filterId);
  return filter.options.filter(option => filter.selection.has(option.id));
};

export const getSelectedOptionNames = (state, getters) => filterId => {
  const selectedOptions = getters.getSelectedOptions(filterId);
  const [firstOption] = selectedOptions.map(option => option.name);
  const extraOptionCount = selectedOptions.length - 1;

  return extraOptionCount
    ? sprintf(__('%{firstOption} +%{extraOptionCount} more'), {
        firstOption,
        extraOptionCount,
      })
    : firstOption;
};

/**
 * Loops through all the filters and returns all the active ones
 * stripping out any that are set to 'all'
 * @returns Object
 * e.g. { type: ['sast'], severity: ['high', 'medium'] }
 */
export const activeFilters = state =>
  state.filters.reduce((acc, filter) => {
    acc[filter.id] = [...filter.selection].filter(option => option !== 'all');
    return acc;
  }, {});

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
