import { DEFAULT_TIME_WINDOW } from '../../../constants';

export default () => ({
  environmentsEndpoint: '',
  environments: [],
  isLoadingEnvironments: false,
  errorLoadingEnvironments: false,
  currentEnvironmentId: -1,
  currentTimeWindow: DEFAULT_TIME_WINDOW,
  wafStatisticsEndpoint: '',
  wafStatistics: {
    totalTraffic: 0,
    anomalousTraffic: 0,
    history: {
      nominal: [],
      anomalous: [],
    },
  },
  isLoadingWafStatistics: false,
  errorLoadingWafStatistics: false,
});
