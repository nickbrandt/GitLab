// eslint-disable-next-line import/prefer-default-export
export const getMetricTypes = state => chartKey =>
  state.metricTypes.filter(m => m.charts.indexOf(chartKey) !== -1);
