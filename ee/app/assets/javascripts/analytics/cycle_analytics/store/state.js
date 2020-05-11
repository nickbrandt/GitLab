export default () => ({
  featureFlags: {},

  startDate: null,
  endDate: null,

  isLoading: false,
  isLoadingStage: false,

  isEmptyStage: false,
  errorCode: null,

  isSavingStageOrder: false,
  errorSavingStageOrder: false,

  selectedGroup: null,
  selectedProjects: [],
  selectedStage: null,

  currentStageEvents: [],

  stages: [],
  summary: [],
  medians: {},
});
