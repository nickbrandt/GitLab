export const getFilter = state => filterId => state.filters.find(filter => filter.id === filterId);

export const getSelectedOptions = (state, getters) => filterId =>
  getters.getFilter(filterId).options.filter(option => option.selected);

/**
 * Loops through all the filters and returns all the selected/active ones
 * stripping out any that are set to 'all'
 * @returns Object
 * e.g. { type: ['sast'], severity: ['high', 'medium'] }
 */
export const activeFilters = (state, getters) =>
  state.filters
    .map(filter => filter.id)
    .reduce(
      (result, filterId) => ({
        ...result,
        [filterId]: getters
          .getSelectedOptions(filterId)
          .map(option => option.id)
          .filter(option => option !== 'all'),
      }),
      {},
    );

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
