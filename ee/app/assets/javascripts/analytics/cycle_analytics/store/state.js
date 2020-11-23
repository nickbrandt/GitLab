export default () => ({
  featureFlags: {},

  startDate: null,
  endDate: null,

  isLoading: false,

  errorCode: null,

  currentGroup: null,
  selectedProjects: [],
  selectedValueStream: null,

  isLoadingValueStreams: false,
  isCreatingValueStream: false,
  isDeletingValueStream: false,

  createValueStreamErrors: {},
  deleteValueStreamError: null,

  stages: [],
  summary: [],
  valueStreams: [],
});
