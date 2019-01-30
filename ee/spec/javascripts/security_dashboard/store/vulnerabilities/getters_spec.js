import createState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import { DAYS } from 'ee/security_dashboard/store/modules/vulnerabilities/constants';
import * as getters from 'ee/security_dashboard/store/modules/vulnerabilities/getters';
import mockHistoryData from '../vulnerabilities/data/mock_data_vulnerabilities_history.json';

describe('vulnerabilities module getters', () => {
  describe('dashboardError', () => {
    it('should return true when both error states exist', () => {
      const errorLoadingVulnerabilities = true;
      const errorLoadingVulnerabilitiesCount = true;
      const state = { errorLoadingVulnerabilities, errorLoadingVulnerabilitiesCount };
      const result = getters.dashboardError(state);

      expect(result).toBe(true);
    });
  });

  describe('dashboardCountError', () => {
    it('should return true if the count error exists', () => {
      const state = {
        errorLoadingVulnerabilitiesCount: true,
      };
      const result = getters.dashboardCountError(state);

      expect(result).toBe(true);
    });

    it('should return false if the list error exists as well', () => {
      const state = {
        errorLoadingVulnerabilities: true,
        errorLoadingVulnerabilitiesCount: true,
      };
      const result = getters.dashboardCountError(state);

      expect(result).toBe(false);
    });
  });

  describe('dashboardListError', () => {
    it('should return true when the list error exists', () => {
      const state = {
        errorLoadingVulnerabilities: true,
      };
      const result = getters.dashboardListError(state);

      expect(result).toBe(true);
    });

    it('should return false if the count error exists as well', () => {
      const state = {
        errorLoadingVulnerabilities: true,
        errorLoadingVulnerabilitiesCount: true,
      };
      const result = getters.dashboardListError(state);

      expect(result).toBe(false);
    });
  });

  describe('getFilteredVulnerabilitiesHistory', () => {
    let state;

    const mockedGetters = () => {
      const getVulnerabilityHistoryByName = name =>
        getters.getVulnerabilityHistoryByName(state)(name);
      return { getVulnerabilityHistoryByName };
    };

    beforeEach(() => {
      state = createState();
      state.vulnerabilitiesHistory = mockHistoryData;
      jasmine.clock().install();
      jasmine.clock().mockDate(new Date(2019, 1, 2));
    });

    afterEach(function() {
      jasmine.clock().uninstall();
    });

    it('should filter the data to the last 30 days and days we have data for', () => {
      state.vulnerabilitiesHistoryDayRange = DAYS.THIRTY;
      const filteredResults = getters.getFilteredVulnerabilitiesHistory(state, mockedGetters())(
        'critical',
      );

      expect(filteredResults.length).toEqual(28);
    });

    it('should filter the data to the last 60 days and days we have data for', () => {
      state.vulnerabilitiesHistoryDayRange = DAYS.SIXTY;
      const filteredResults = getters.getFilteredVulnerabilitiesHistory(state, mockedGetters())(
        'critical',
      );

      expect(filteredResults.length).toEqual(58);
    });

    it('should filter the data to the last 90 days and days we have data for', () => {
      state.vulnerabilitiesHistoryDayRange = DAYS.NINETY;
      const filteredResults = getters.getFilteredVulnerabilitiesHistory(state, mockedGetters())(
        'critical',
      );

      expect(filteredResults.length).toEqual(88);
    });
  });
});
