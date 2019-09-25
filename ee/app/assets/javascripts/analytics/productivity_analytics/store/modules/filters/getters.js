import { urlParamsToObject } from '~/lib/utils/common_utils';
import { chartKeys, scatterPlotAddonQueryDays } from '../../../constants';

/**
 * Returns an object of common filter parameters based on the filter's state
 * which will be used for querying the API to retrieve chart and MR table data.
 * The returned object hast the following form:
 *
 * {
 *   group_id: 'gitlab-org',
 *   project_id: 'gitlab-org/gitlab-test',
 *   author_username: 'author',
 *   milestone_title: 'my milestone',
 *   label_name: ['my label', 'yet another label'],
 *   merged_at_after: '2019-05-09T16:20:18.393Z'
 * }
 *
 */
export const getCommonFilterParams = state => chartKey => {
  const { groupNamespace, projectPath, filters } = state;
  const { author_username, milestone_title, label_name } = urlParamsToObject(filters);

  // for the scatterplot we need to add additional 30 days to the desired date in the past
  const daysInPast =
    chartKey && chartKey === chartKeys.scatterplot
      ? state.daysInPast + scatterPlotAddonQueryDays
      : state.daysInPast;

  return {
    group_id: groupNamespace,
    project_id: projectPath,
    author_username,
    milestone_title,
    label_name,
    merged_at_after: `${daysInPast}days`,
  };
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
