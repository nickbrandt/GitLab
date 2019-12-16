export default () => ({
  environmentsEndpoint: '',
  environments: [],
  isLoadingEnvironments: false,
  errorLoadingEnvironments: false,
  currentEnvironmentId: -1,
  wafStatisticsEndpoint: '',
  wafStatistics: {
    totalTraffic: 0,
    trafficAllowed: 0,
    trafficBlocked: 0,
    history: {
      allowed: [],
      blocked: [],
    },
  },
  isWafStatisticsLoading: false,
  errorLoadingWafStatistics: false,
});
