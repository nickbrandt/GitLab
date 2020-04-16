import { getTasksByTypeData } from '../../../utils';

export const tasksByTypeChartData = ({ tasksByType, startDate, endDate }) => {
  if (tasksByType && tasksByType.data.length) {
    return getTasksByTypeData({
      data: tasksByType.data,
      startDate,
      endDate,
    });
  }
  return { groupBy: [], data: [], seriesNames: [] };
};

export default { tasksByTypeChartData };
