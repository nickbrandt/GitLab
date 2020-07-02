import { addIconStatus, formattedTime, sortTestCases } from './utils';

export const getTestSuites = state => {
  const { test_suites: testSuites = [] } = state.testReports;

  return testSuites.map(suite => ({
    ...suite,
    formattedTime: formattedTime(suite.total_time),
  }));
};

export const getSuiteTests = state => {
  const { selectedSuiteIndex } = state;
  const selectedSuite = state.testReports.test_suites[selectedSuiteIndex];

  if (selectedSuite.test_cases) {
    return selectedSuite.test_cases.sort(sortTestCases).map(addIconStatus);
  }

  return [];
};

export const getSelectedSuite = state => state.testReports.test_suites[state.selectedSuiteIndex];

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
