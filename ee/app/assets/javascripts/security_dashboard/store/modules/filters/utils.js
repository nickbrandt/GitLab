import { isSubset } from '~/lib/utils/set';
import { ALL } from './constants';

const createSelection = selectionObj => {
  return Object.values(selectionObj).reduce((acc, curr) => {
    return new Set([...acc, ...curr]);
  }, new Set());
};

export const isBaseFilterOption = id => id === ALL;

/**
 * Returns whether or not the given state filter has a valid selection,
 * considering its available options.
 * @param {Object} filter The filter from the state to check.
 * @returns boolean
 */
export const hasValidSelection = ({ selection, options }) =>
  isSubset(selection, new Set(options.map(({ id }) => id)));

/**
 * Takes a filter array and a selected payload.
 * It then either adds or removes that option from the appropriate selected filter.
 * With a few extra exceptions around the `ALL` special case.
 * @param {Array} filters the filters to mutate
 * @param {Object} payload
 * @param {String} payload.optionId the ID of the option that was just selected
 * @param {String} payload.filterId the ID of the filter that the selected option belongs to
 * @returns {Array} the mutated filters array
 */
export const setFilter = (filters, { filterIds, optionIds }) => {
  return filters.map(filter => {
    if (Object.keys(filterIds).some(id => filter.ids[id])) {
      const { selectionObj: selection } = filter;
      let newSelection;

      /* eslint-disable-next-line guard-for-in, no-restricted-syntax */
      for (const [key, value] of Object.entries(optionIds)) {
        if (Array.isArray(value) && !value.length) {
          continue;
        }
        if (value === ALL) {
          newSelection = { ALL: [ALL] };
          break;
        } else if (selection[key]?.includes(value)) {
          newSelection = { ...selection };
          if (newSelection[key].length === 1) {
            delete newSelection[key];
            if (!Object.keys(newSelection).length) {
              newSelection = { ALL: [ALL] };
            }
          } else {
            newSelection[key].splice(newSelection[key].indexOf(value), 1);
          }
        } else {
          if (!newSelection) {
            newSelection = selection.ALL ? {} : { ...selection };
          }
          if (newSelection[key]) {
            newSelection[key] = newSelection[key].concat(value);
          } else {
            newSelection[key] = Array.isArray(value) ? value : [value];
          }
        }
      }

      return {
        ...filter,
        selection: createSelection(newSelection),
        selectionObj: newSelection,
      };
    }
    return filter;
  });
};
