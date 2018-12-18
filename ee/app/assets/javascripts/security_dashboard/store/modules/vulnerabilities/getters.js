export const dashboardError = state =>
  state.errorLoadingVulnerabilities && state.errorLoadingVulnerabilitiesCount;
export const dashboardListError = state =>
  state.errorLoadingVulnerabilities && !state.errorLoadingVulnerabilitiesCount;
export const dashboardCountError = state =>
  !state.errorLoadingVulnerabilities && state.errorLoadingVulnerabilitiesCount;

export default () => {};
