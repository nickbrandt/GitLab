export default (summaryEndpoint, fullReportEndpoint) => ({
  summaryEndpoint,
  fullReportEndpoint,
  summary: {},
  testReports: {},
  selectedSuite: {},
  isLoading: false,
  hasFullReport: false,
});
