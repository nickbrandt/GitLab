import { TASKS_BY_TYPE_SUBJECT_ISSUE } from '../constants';

export default () => ({
  featureFlags: {},

  startDate: null,
  endDate: null,

  isLoading: false,
  isLoadingStage: false,
  isLoadingTasksByTypeChart: false,
  isLoadingTasksByTypeChartTopLabels: false,

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
  topRankedLabels: [],
  medians: {},

  customStageFormEvents: [],
  customStageFormErrors: null,
  customStageFormInitialData: null,

  tasksByType: {
    subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
    selectedLabelIds: [],
    data: [],
  },
});
