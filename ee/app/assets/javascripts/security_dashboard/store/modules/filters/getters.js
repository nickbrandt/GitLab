export const getFilter = state => filterId => state.filters.find(filter => filter.id === filterId);

export const getSelectedOptions = (state, getters) => filterId =>
  getters.getFilter(filterId).options.filter(option => option.selected);

export const getSelectedOptionIds = (state, getters) => filterId =>
  getters.getSelectedOptions(filterId).map(option => option.id);

export const getSelectedOptionNames = (state, getters) => filterId => {
  const selectedOptions = getters.getSelectedOptions(filterId);
  const [firstOption] = selectedOptions.map(option => option.name);
  return selectedOptions.length > 1
    ? `${firstOption} +${selectedOptions.length - 1} more`
    : `${firstOption}`;
};

export const getFilterIds = state => state.filters.map(filter => filter.id);

/**
 * Loops through all the filters and returns all the active ones
 * stripping out any that are set to 'all'
 * @returns Object
 * e.g. { type: ['sast'], severity: ['high', 'medium'] }
 */
export const activeFilters = (state, getters) =>
  getters.getFilterIds.reduce(
    (result, filterId) => ({
      ...result,
      [filterId]: getters.getSelectedOptionIds(filterId).filter(option => option !== 'all'),
    }),
    {},
  );

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
