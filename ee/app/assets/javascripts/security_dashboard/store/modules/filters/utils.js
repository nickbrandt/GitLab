import { isSubset } from '~/lib/utils/set';
import { ALL } from './constants';

export const isBaseFilterOption = id => id === ALL;

/**
 * Returns whether or not the given state filter has a valid selection,
 * considering its available options.
 * @param {Object} filter The filter from the state to check.
 * @returns boolean
 */
export const hasValidSelection = ({ selection, options }) =>
  isSubset(selection, new Set(options.map(({ id }) => id)));
