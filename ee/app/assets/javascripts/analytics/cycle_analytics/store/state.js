import { TASKS_BY_TYPE_SUBJECT_ISSUE } from '../constants';

export default () => ({
  endpoints: {
    cycleAnalyticsData: null,
    stageData: null,
    cycleAnalyticsStagesAndEvents: null,
    summaryData: null,
  },

  startDate: null,
  endDate: null,

  isLoading: false,
  isLoadingStage: false,

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
    subject: TASKS_BY_TYPE_SUBJECT_ISSUE, // issues | merge_requests, defaults to issues
    // list of selected labels for the tasks by type chart
    labelIds: [],
    data: []
  },
});
