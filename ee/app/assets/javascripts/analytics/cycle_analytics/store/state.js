import { TASKS_BY_TYPE_SUBJECT_ISSUE } from '../constants';

export default () => ({
  featureFlags: {},

  startDate: null,
  endDate: null,

  isLoading: false,
  isLoadingStage: false,
  isLoadingChartData: false,
  isLoadingDurationChart: false,

  isEmptyStage: false,
  errorCode: null,

  isAddingCustomStage: false,
  isSavingCustomStage: false,

  selectedGroup: null,
  selectedProjectIds: [],
  selectedStageId: null,

  currentStageEvents: [],

  stages: [],
  summary: [],
  labels: [],

  customStageFormEvents: [],
  tasksByType: {
    subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
    labelIds: [],
    data: [],
  },

  durationData: [],
});
