/**
 * This util method takes the global page filters and transforms parameters which
 * are not standardized between the internal issues analytics api and the public
 * issues api.
 *
 * @param {Object} filters the global filters used to fetch issues data
 *
 * @returns {Object} the transformed filters for the public api
 */
// eslint-disable-next-line import/prefer-default-export
export const transformFilters = ({
  label_name: labels = null,
  milestone_title: milestone = null,
  ...restOfFilters
}) => ({
  ...restOfFilters,
  labels,
  milestone,
});
