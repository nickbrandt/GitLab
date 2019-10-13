export default () => ({
  endpoints: {
    cycleAnalyticsData: null,
    stageData: null,
  },

  startDate: null,
  endDate: null,

  isLoading: false,
  isLoadingStage: false,
  isLoadingStageForm: false,

  isEmptyStage: false,
  errorCode: null,

  isAddingCustomStage: false,

  selectedGroup: null,
  selectedProjectIds: [],
  selectedStageName: null,

  currentStageEvents: [],

  stages: [],
  summary: [],
  labels: [],

  customStageFormEvents: [],
});
