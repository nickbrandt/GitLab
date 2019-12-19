import dateFormat from 'dateformat';
import httpStatus from '~/lib/utils/http_status';
import { dateFormats } from '../../shared/constants';
import { getDurationChartData, getTasksByTypeData } from '../utils';

export const hasNoAccessError = state => state.errorCode === httpStatus.FORBIDDEN;

export const currentGroupPath = ({ selectedGroup }) =>
  selectedGroup && selectedGroup.fullPath ? selectedGroup.fullPath : null;

export const cycleAnalyticsRequestParams = ({
  startDate = null,
  endDate = null,
  selectedProjectIds = [],
}) => ({
  project_ids: selectedProjectIds,
  created_after: startDate ? dateFormat(startDate, dateFormats.isoDate) : null,
  created_before: endDate ? dateFormat(endDate, dateFormats.isoDate) : null,
});

export const durationChartPlottableData = state => {
  const { durationData, startDate, endDate } = state;
  const selectedStagesDurationData = durationData.filter(stage => stage.selected);
  const plottableData = getDurationChartData(selectedStagesDurationData, startDate, endDate);

  return plottableData.length ? plottableData : null;
};

export const tasksByTypeChartData = ({ tasksByType, startDate, endDate }) => {
  // TODO: remove this check, return empty data if need be
  if (tasksByType && tasksByType.data.length) {
    return getTasksByTypeData({
      data: tasksByType.data,
      startDate,
      endDate,
    });
  }
  return {};
};
