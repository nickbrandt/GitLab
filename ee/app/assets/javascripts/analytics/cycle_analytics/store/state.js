export default () => ({
  featureFlags: {},

  startDate: null,
  endDate: null,

  isLoading: false,
  isLoadingStage: false,

  isEmptyStage: false,
  errorCode: null,

  isSavingCustomStage: false,
  isCreatingCustomStage: false,
  isEditingCustomStage: false,
  isSavingStageOrder: false,
  errorSavingStageOrder: false,

  selectedGroup: null,
  selectedProjects: [],
  selectedStage: null,

  currentStageEvents: [],

  stages: [],
  summary: [],
  medians: {},

  customStageFormEvents: [],
  customStageFormErrors: null,
  customStageFormInitialData: null,
});
