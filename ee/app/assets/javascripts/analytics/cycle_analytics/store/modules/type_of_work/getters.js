import { getTasksByTypeData } from '../../../utils';

export const tasksByTypeChartData = ({ data = [] } = {}, _, rootState = {}) => {
  const { startDate = null, endDate = null } = rootState;
  return data.length
    ? getTasksByTypeData({
        data,
        startDate,
        endDate,
      })
    : { groupBy: [], data: [], seriesNames: [] };
};

export default () => ({ tasksByTypeChartData });
