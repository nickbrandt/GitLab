export default () => ({
  featureFlags: {},

  startDate: null,
  endDate: null,

  isLoading: false,

  isEmptyStage: false,
  errorCode: null,

  isSavingStageOrder: false,
  errorSavingStageOrder: false,

  selectedGroup: null,
  selectedProjects: [],
  selectedStage: null,

  stages: [],
  summary: [],
  medians: {},
});
