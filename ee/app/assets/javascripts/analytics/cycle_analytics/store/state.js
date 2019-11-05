export default () => ({
  endpoints: {
    cycleAnalyticsData: null,
    stageData: null,
    cycleAnalyticsStagesAndEvents: null,
    summaryData: null,
  },

  startDate: null,
  endDate: null,

  isLoading: false,
  isLoadingStage: false,

  isEmptyStage: false,
  errorCode: null,

  isAddingCustomStage: false,

  selectedGroup: null,
  selectedProjectIds: [],
  selectedStageId: null,

  currentStageEvents: [],

  stages: [],
  summary: [],
  labels: [],

  customStageFormEvents: [],
});
