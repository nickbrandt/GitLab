import { addIconStatus, formattedTime, sortTestCases } from './utils';

export const getTestSuites = state => {
  const { test_suites: testSuites = [] } = state.testReports;

  return testSuites.map(suite => ({
    ...suite,
    formattedTime: formattedTime(suite.total_time),
  }));
};

// We want to use this to get the selected suite based on state
// but we also want to use this when selecting a state
// so we can make it return a method to call
export const getSelectedSuite = state => (index = state.selectedSuiteIndex) =>
  state.testReports?.test_suites?.[index] || {};

export const getSuiteTests = state => {
  const { test_cases: testCases = [] } = getSelectedSuite(state)();
  return testCases.sort(sortTestCases).map(addIconStatus);
};
