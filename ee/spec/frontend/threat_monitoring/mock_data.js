export const mockEnvironmentsResponse = {
  environments: [
    {
      id: 1129970,
      name: 'production',
      state: 'available',
    },
    {
      id: 1156094,
      name: 'review/enable-blocking-waf',
      state: 'available',
    },
  ],
  available_count: 2,
  stopped_count: 5,
};

export const mockWafStatisticsResponse = {
  total_traffic: 31500,
  traffic_allowed: 0.11,
  traffic_blocked: 0.89,
  history: {
    allowed: [['<timestamp>', 25], ['<timestamp>', 30]],
    blocked: [['<timestamp>', 15], ['<timestamp>', 20]],
  },
};
