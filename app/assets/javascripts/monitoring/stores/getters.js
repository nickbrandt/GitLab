export const dashboardHasChanged = (state) => {
  // TODO Dashboards should be comparable, so we should ignore metrics
  return JSON.stringify(state.dashboard) !== JSON.stringify(state.originalDashboard)
}

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
