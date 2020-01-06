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
  total_traffic: 2703,
  anomalous_traffic: 0.03,
  history: {
    nominal: [['2019-12-04T00:00:00.000Z', 56], ['2019-12-05T00:00:00.000Z', 2647]],
    anomalous: [['2019-12-04T00:00:00.000Z', 1], ['2019-12-05T00:00:00.000Z', 83]],
  },
};
