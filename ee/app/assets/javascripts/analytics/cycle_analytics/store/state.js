import { TASKS_BY_TYPE_SUBJECT_ISSUE } from '../constants';

export default () => ({
  featureFlags: {},

  startDate: null,
  endDate: null,

  isLoading: false,
  isLoadingStage: false,
  isLoadingTasksByTypeChart: false,
  isLoadingDurationChart: false,

  isEmptyStage: false,
  errorCode: null,

  isSavingCustomStage: false,
  isCreatingCustomStage: false,
  isEditingCustomStage: false,

  selectedGroup: null,
  selectedProjectIds: [],
  selectedStage: null,

  currentStageEvents: [],

  stages: [],
  summary: [],
  labels: [],
  medians: {},

  customStageFormEvents: [],
  tasksByType: {
    subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
    labelIds: [],
    data: [],
  },

  durationData: [],
});
