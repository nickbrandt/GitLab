import { mergeUrlParams, getParameterValues, removeParams } from '~/lib/utils/url_utility';

const LABEL_FILTER_NAME = 'label_name[]';
const MILESTONE_FILTER_NAME = 'milestone_title';

/**
 * This util method takes the issues api endpoint with global page filters
 * and transforms parameters which are not standardized between the internal
 * issues analytics api and the public issues api.
 *
 * @param {String} endpoint the api endpoint with global filters used to fetch issues data
 *
 * @returns {String} The endpoint formatted for the public api
 */
// eslint-disable-next-line import/prefer-default-export
export const transformIssuesApiEndpoint = endpoint => {
  const cleanEndpoint = removeParams([LABEL_FILTER_NAME, MILESTONE_FILTER_NAME], endpoint, true);
  const labels = getParameterValues(LABEL_FILTER_NAME, endpoint);
  const milestone = getParameterValues(MILESTONE_FILTER_NAME, endpoint);

  return mergeUrlParams({ labels, milestone }, cleanEndpoint);
};
