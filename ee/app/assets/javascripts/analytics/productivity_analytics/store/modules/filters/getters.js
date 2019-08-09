import { urlParamsToObject } from '~/lib/utils/common_utils';

/**
 * Returns an object of common filter parameters based on the filter's state
 * which will be used for querying the API to retrieve chart and MR table data.
 * The returned object hast the following form:
 *
 * {
 *   group_id: 'gitlab-org',
 *   project_id: 'gitlab-test',
 *   author_username: 'author',
 *   milestone_title: 'my milestone',
 *   label_name: ['my label', 'yet another label'],
 *   merged_at_after: '2019-05-09T16:20:18.393Z'
 * }
 *
 */
export const getCommonFilterParams = (state, getters) => {
  const { groupNamespace, projectPath, filters } = state;
  const { author_username, milestone_title, label_name } = urlParamsToObject(filters);

  return {
    group_id: groupNamespace,
    project_id: projectPath,
    author_username,
    milestone_title,
    label_name,
    merged_at_after: getters.mergedOnAfterDate,
  };
};

/**
 * Computes the "merged_at_after" date which will be used in the getCommonFilterParams getter.
 * It subtracts the number of days (based on the state's daysInPast property) from today's date
 * and returns the new date.
 */
export const mergedOnAfterDate = state => {
  const d = new Date();
  return new Date(d.setTime(d.getTime() - state.daysInPast * 24 * 60 * 60 * 1000)).toISOString();
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
