import dateFormat from 'dateformat';
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import { beginOfDayTime, endOfDayTime } from '~/lib/utils/datetime_utility';
import * as types from './mutation_types';
import { chartKeys } from '../../../constants';
import { dateFormats } from '../../../../shared/constants';

export const setInitialData = ({ commit, dispatch }, { skipFetch = false, data }) => {
  commit(types.SET_INITIAL_DATA, data);

  if (skipFetch) return Promise.resolve();

  return dispatch('charts/fetchChartData', chartKeys.main, { root: true }).then(() => {
    dispatch('charts/fetchSecondaryChartData', null, { root: true });
    // let's reset the page on the MR table and fetch data
    dispatch('table/setPage', 0, { root: true });
  });
};

export const setGroupNamespace = ({ commit, dispatch }, groupNamespace) => {
  commit(types.SET_GROUP_NAMESPACE, groupNamespace);

  historyPushState(setUrlParams({ group_id: groupNamespace }, window.location.href, true));

  // let's reset the current selection first
  // with skipReload=true we avoid data from being fetched here
  dispatch('charts/resetMainChartSelection', true, { root: true });

  // let's fetch the main chart data first to see if the user has access to the selected group
  // if there's no 403, then we fetch all remaining chart data and table data
  return dispatch('charts/fetchChartData', chartKeys.main, { root: true }).then(() => {
    dispatch('charts/fetchSecondaryChartData', null, { root: true });
    // let's reset the page on the MR table and fetch data
    dispatch('table/setPage', 0, { root: true });
  });
};

export const setProjectPath = ({ commit, dispatch, state }, projectPath) => {
  commit(types.SET_PROJECT_PATH, projectPath);

  historyPushState(
    setUrlParams(
      { group_id: state.groupNamespace, project_id: projectPath },
      window.location.href,
      true,
    ),
  );

  dispatch('charts/resetMainChartSelection', true, { root: true });

  return dispatch('charts/fetchChartData', chartKeys.main, { root: true }).then(() => {
    dispatch('charts/fetchSecondaryChartData', null, { root: true });
    // let's reset the page on the MR table and fetch data
    dispatch('table/setPage', 0, { root: true });
  });
};

export const setFilters = (
  { commit, dispatch },
  { author_username, label_name, milestone_title },
) => {
  commit(types.SET_FILTERS, {
    authorUsername: author_username,
    labelName: label_name,
    milestoneTitle: milestone_title,
  });

  historyPushState(setUrlParams({ author_username, 'label_name[]': label_name, milestone_title }));

  dispatch('charts/resetMainChartSelection', true, { root: true });

  return dispatch('charts/fetchChartData', chartKeys.main, { root: true }).then(() => {
    dispatch('charts/fetchSecondaryChartData', null, { root: true });
    // let's reset the page on the MR table and fetch data
    dispatch('table/setPage', 0, { root: true });
  });
};

export const setDateRange = ({ commit, dispatch }, { startDate, endDate }) => {
  commit(types.SET_DATE_RANGE, { startDate, endDate });

  const mergedAfter = `${dateFormat(startDate, dateFormats.isoDate)}${beginOfDayTime}`;
  const mergedBefore = `${dateFormat(endDate, dateFormats.isoDate)}${endOfDayTime}`;

  historyPushState(setUrlParams({ merged_after: mergedAfter, merged_before: mergedBefore }));

  dispatch('charts/resetMainChartSelection', true, { root: true });

  return dispatch('charts/fetchChartData', chartKeys.main, { root: true }).then(() => {
    dispatch('charts/fetchSecondaryChartData', null, { root: true });
    // let's reset the page on the MR table and fetch data
    dispatch('table/setPage', 0, { root: true });
  });
};
