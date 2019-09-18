import { DEFAULT_DATA_TIME_FRAME } from '../constants';

export default () => ({
  endpoints: {
    cycleAnalyticsData: '',
    stageData: '',
  },

  dataTimeframe: DEFAULT_DATA_TIME_FRAME,

  isLoading: false,
  isLoadingStage: false,

  isEmptyStage: false,

  isAddingCustomStage: false,

  selectedGroup: null,
  selectedProjectIds: [],
  selectedStageName: null,

  events: [],
  stages: [],
  summary: [],
});
