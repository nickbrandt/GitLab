import {
  SAST_HAS_ERROR,
  SAST_IS_LOADING,
} from 'ee/vue_shared/security_reports/store/modules/sast/constants';
import createState from 'ee/vue_shared/security_reports/store/modules/sast/state';
import * as getters from 'ee/vue_shared/security_reports/store/modules/sast/getters';

const newState = (config = {}) => ({
  ...createState(),
  ...config,
});

describe('groupedSummaryText', () => {
  it("should return the error message if there's an error", () => {
    const state = newState({ hasError: true });
    const result = getters.groupedSummaryText(state);

    expect(result).toBe(SAST_HAS_ERROR);
  });

  it("should return the loading message if it's still loading", () => {
    const state = newState({ isLoading: true });
    const result = getters.groupedSummaryText(state);

    expect(result).toBe(SAST_IS_LOADING);
  });

  it('should call groupedTextBuilder if everything is fine', () => {
    const state = newState();
    const result = getters.groupedSummaryText(state);

    expect(result).toBe('SAST detected no vulnerabilities for the source branch only');
  });
});

describe('statusIcon', () => {
  it("should return `loading` when we're still loading", () => {
    const state = newState({ isLoading: true });
    const result = getters.statusIcon(state);

    expect(result).toBe('loading');
  });

  it("should return `warning` when there's an issue", () => {
    const state = newState({ hasError: true });
    const result = getters.statusIcon(state);

    expect(result).toBe('warning');
  });

  it('should return `success` when nothing is wrong', () => {
    const sast = newState();
    const result = getters.statusIcon(sast);

    expect(result).toBe('success');
  });
});

describe('issueCount', () => {
  it('should return `newIssuesCount` if it exists', () => {
    const newIssuesCount = 100;
    const state = newState({ newIssuesCount });
    const result = getters.issueCount(state);

    expect(result).toEqual(newIssuesCount);
  });

  it('should return the length of `newIssues` if `newIssuesCount does not exist`', () => {
    const newIssues = [1, 2, 3, 4, 5, 6];
    const state = newState({ newIssues });
    const result = getters.issueCount(state);

    expect(result).toEqual(newIssues.length);
  });

  it('should return 0 if there are no issues and no issue count', () => {
    const state = newState();
    const result = getters.issueCount(state);

    expect(result).toEqual(0);
  });
});

describe('summaryText', () => {
  it('should return the correct text when there are no vulnerabilities', () => {
    const state = newState();
    const result = getters.summaryText(state, { issueCount: 0 });

    expect(result).toBe('SAST detected no vulnerabilities');
  });

  it("should return the correct text when there's only one vulnerability", () => {
    const state = newState();
    const result = getters.summaryText(state, { issueCount: 1 });

    expect(result).toBe('SAST detected 1 vulnerability');
  });

  it('should return the correct text when there are multiple vulnerabilities', () => {
    const state = newState();
    const result = getters.summaryText(state, { issueCount: 100 });

    expect(result).toBe('SAST detected 100 vulnerabilities');
  });
});
