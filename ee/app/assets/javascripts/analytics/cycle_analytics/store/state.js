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
  selectedAuthor: null,
  selectedMilestone: null,
  selectedAssignees: [],
  selectedLabels: [], // NOTE: Filters for the VSA endpoints use label name
  selectedLabelIds: [], // NOTE: The tasks by type chart uses labelIds

  currentStageEvents: [],

  stages: [],
  summary: [],
  medians: {},
});
