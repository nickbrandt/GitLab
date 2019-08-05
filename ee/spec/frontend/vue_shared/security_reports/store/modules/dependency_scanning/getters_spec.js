import {
  DEPENDENCY_SCANNING_HAS_ERROR,
  DEPENDENCY_SCANNING_IS_LOADING,
} from 'ee/vue_shared/security_reports/store/modules/dependency_scanning/constants';
import * as getters from 'ee/vue_shared/security_reports/store/modules/dependency_scanning/getters';

const createReport = (config = {}) => ({
  paths: [],
  newIssues: [],
  ...config,
});

describe('dependency scanning getters', () => {
  describe('groupedDependencyText', () => {
    it("should return the error message if there's an error", () => {
      const report = createReport({ hasError: true });
      const result = getters.groupedDependencyText(report);

      expect(result).toBe(DEPENDENCY_SCANNING_HAS_ERROR);
    });

    it("should return the loading message if it's still loading", () => {
      const report = createReport({ isLoading: true });
      const result = getters.groupedDependencyText(report);

      expect(result).toBe(DEPENDENCY_SCANNING_IS_LOADING);
    });

    it('should call groupedTextBuilder if everything is fine', () => {
      const report = createReport();
      const result = getters.groupedDependencyText(report);

      expect(result).toBe(
        'Dependency scanning detected no vulnerabilities for the source branch only',
      );
    });
  });

  describe('dependencyScanningStatusIcon', () => {
    it("should return `loading` when we're still loading", () => {
      const report = createReport({ isLoading: true });
      const result = getters.dependencyScanningStatusIcon(report);

      expect(result).toBe('loading');
    });

    it("should return `warning` when there's an issue", () => {
      const report = createReport({ hasError: true });
      const result = getters.dependencyScanningStatusIcon(report);

      expect(result).toBe('warning');
    });

    it('should return `success` when nothing is wrong', () => {
      const report = createReport();
      const result = getters.dependencyScanningStatusIcon(report);

      expect(result).toBe('success');
    });
  });
});
