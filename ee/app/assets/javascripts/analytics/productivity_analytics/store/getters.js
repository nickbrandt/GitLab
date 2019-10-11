export const getMetricTypes = state => chartKey =>
  state.metricTypes.filter(m => m.charts.indexOf(chartKey) !== -1);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
