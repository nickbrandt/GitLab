import dateFormat from 'dateformat';
import { dateFormats } from '~/analytics/shared/constants';
import { filterToQueryObject } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { transformStagesForPathNavigation, filterStagesByHiddenStatus } from '../utils';

export const pathNavigationData = ({ stages, medians, stageCounts, selectedStage }) => {
  return transformStagesForPathNavigation({
    stages: filterStagesByHiddenStatus(stages, false),
    medians,
    stageCounts,
    selectedStage,
  });
};

export const requestParams = (state) => {
  const {
    selectedStage: { id: stageId = null },
    currentGroup: { path: groupId },
    selectedValueStream: { id: valueStreamId },
  } = state;
  return { valueStreamId, groupId, stageId };
};

const dateRangeParams = ({ createdAfter, createdBefore }) => ({
  created_after: createdAfter ? dateFormat(createdAfter, dateFormats.isoDate) : null,
  created_before: createdBefore ? dateFormat(createdBefore, dateFormats.isoDate) : null,
});

export const legacyFilterParams = ({ startDate }) => {
  return {
    'cycle_analytics[start_date]': startDate,
  };
};

export const filterParams = (state) => {
  const {
    id,
    filters: {
      authors: { selected: selectedAuthor },
      milestones: { selected: selectedMilestone },
      assignees: { selectedList: selectedAssigneeList },
      labels: { selectedList: selectedLabelList },
    },
  } = state;

  const filterBarQuery = filterToQueryObject({
    milestone_title: selectedMilestone,
    author_username: selectedAuthor,
    label_name: selectedLabelList,
    assignee_username: selectedAssigneeList,
  });

  return {
    project_ids: [id],
    ...dateRangeParams(state),
    ...filterBarQuery,
  };
};
