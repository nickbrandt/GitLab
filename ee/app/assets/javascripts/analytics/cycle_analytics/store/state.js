export default () => ({
  featureFlags: {},

  startDate: null,
  endDate: null,

  isLoading: false,

  errorCode: null,

  currentGroup: null,
  selectedProjects: [],
  selectedStage: null,
  selectedValueStream: null,

  currentStageEvents: [],

  isLoadingValueStreams: false,
  isCreatingValueStream: false,
  isDeletingValueStream: false,

  createValueStreamErrors: {},
  deleteValueStreamError: null,

  stages: [],
  selectedStageError: '',
  summary: [],
  medians: {},
  valueStreams: [],
});
