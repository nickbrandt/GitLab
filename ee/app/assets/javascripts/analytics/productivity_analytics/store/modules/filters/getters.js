import dateFormat from 'dateformat';
import { getDateInPast, beginOfDayTime, endOfDayTime } from '~/lib/utils/datetime_utility';
import { chartKeys, scatterPlotAddonQueryDays } from '../../../constants';
import { dateFormats } from '../../../../shared/constants';

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
 *   merged_at_after: '2019-06-11T00:00:00Z'
 *   merged_at_before: '2019-09-09T23:59:59Z'
 * }
 *
 */
export const getCommonFilterParams = state => chartKey => {
  const {
    groupNamespace,
    projectPath,
    startDate,
    endDate,
    authorUsername,
    labelName,
    milestoneTitle,
  } = state;

  // for the scatterplot we need to remove 30 days from the state's merged_at_after date
  const mergedAtAfterDate =
    chartKey && chartKey === chartKeys.scatterplot
      ? dateFormat(getDateInPast(startDate, scatterPlotAddonQueryDays), dateFormats.isoDate)
      : dateFormat(startDate, dateFormats.isoDate);

  return {
    group_id: groupNamespace,
    project_id: projectPath,
    author_username: authorUsername,
    milestone_title: milestoneTitle,
    label_name: labelName,
    merged_at_after: `${mergedAtAfterDate}${beginOfDayTime}`,
    merged_at_before: `${dateFormat(endDate, dateFormats.isoDate)}${endOfDayTime}`,
  };
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
