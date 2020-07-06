import { getJSONFixture } from 'helpers/fixtures';
import * as types from '~/pipelines/stores/test_reports/mutation_types';
import mutations from '~/pipelines/stores/test_reports/mutations';

describe('Mutations TestReports Store', () => {
  let mockState;

  const testReports = getJSONFixture('pipelines/test_report.json');

  const defaultState = {
    endpoint: '',
    testReports: {},
    selectedSuiteIndex: null,
    isLoading: false,
    hasFullReport: false,
  };

  beforeEach(() => {
    mockState = { ...defaultState };
  });

  describe('set reports', () => {
    it('should set testReports', () => {
      const expectedState = { ...mockState, testReports, hasFullReport: true };
      mutations[types.SET_REPORTS](mockState, testReports);

      expect(mockState).toEqual(expectedState);
    });
  });

  describe('set selected suite', () => {
    it('should set selectedSuite', () => {
      const selectedSuiteIndex = 1;
      mutations[types.SET_SELECTED_SUITE](mockState, selectedSuiteIndex);

      expect(mockState.selectedSuiteIndex).toEqual(selectedSuiteIndex);
    });
  });

  describe('set summary', () => {
    it('should set summary', () => {
      const summary = { total_count: 1 };
      mutations[types.SET_SUMMARY](mockState, summary);

      expect(mockState.testReports).toEqual(summary);
    });
  });

  describe('set loading', () => {
    it('should set to true', () => {
      const expectedState = { ...mockState, isLoading: true };
      mutations[types.SET_LOADING](mockState, true);

      expect(mockState.isLoading).toEqual(expectedState.isLoading);
    });

    it('should set to false', () => {
      const expectedState = { ...mockState, isLoading: false };
      mockState.isLoading = true;

      mutations[types.SET_LOADING](mockState, false);

      expect(mockState.isLoading).toEqual(expectedState.isLoading);
    });
  });
});
