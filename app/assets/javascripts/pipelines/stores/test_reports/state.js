export default ({ fullReportEndpoint = '', summaryEndpoint = '' }) => ({
  summaryEndpoint,
  fullReportEndpoint,
  testReports: {},
  selectedSuiteIndex: null,
  isLoading: false,
  hasFullReport: false,
});
