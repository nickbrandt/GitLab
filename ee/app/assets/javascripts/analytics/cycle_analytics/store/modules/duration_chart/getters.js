import { getDurationChartData, getDurationChartMedianData } from '../../../utils';

export const durationChartPlottableData = (state, _, rootState) => {
  const { startDate, endDate } = rootState;
  const { durationData } = state;
  const selectedStagesDurationData = durationData.filter(stage => stage.selected);
  const plottableData = getDurationChartData(selectedStagesDurationData, startDate, endDate);

  return plottableData.length ? plottableData : [];
};

export const durationChartMedianData = (state, _, rootState) => {
  const { startDate, endDate } = rootState;
  const { durationMedianData } = state;
  const selectedStagesDurationMedianData = durationMedianData.filter(stage => stage.selected);
  const plottableData = getDurationChartMedianData(
    selectedStagesDurationMedianData,
    startDate,
    endDate,
  );

  return plottableData.length ? plottableData : [];
};
