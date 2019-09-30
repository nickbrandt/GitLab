import { DEFAULT_DATA_TIME_FRAME } from '../constants';

export default () => ({
  endpoints: {
    cycleAnalyticsData: '',
    stageData: '',
  },

  dataTimeframe: DEFAULT_DATA_TIME_FRAME,

  isLoading: false,
  isLoadingStage: false,
  isLoadingStageForm: false,

  isEmptyStage: false,
  errorCode: null,

  isAddingCustomStage: false,

  selectedGroup: null,
  selectedProjectIds: [],
  selectedStageName: null,

  currentStageEvents: [],

  stages: [],
  summary: [],
  labels: [],

  customStageFormEvents: [],
});
