import { statusIcon as getStatusIcon, groupedReportText, summaryTextBuilder } from '../../utils';
import { SAST, SAST_HAS_ERROR, SAST_IS_LOADING } from './constants';

export const groupedSummaryText = state =>
  groupedReportText(state, SAST, SAST_HAS_ERROR, SAST_IS_LOADING);

export const statusIcon = ({ isLoading, hasError, newIssues }) =>
  getStatusIcon(isLoading, hasError, newIssues.length);

// If we're using the new API, we fetch the count.
// If not, we fall back to checking the length.
export const issueCount = ({ newIssuesCount, newIssues }) =>
  newIssuesCount === null ? newIssues.length : newIssuesCount;

export const summaryText = (state, getters) => summaryTextBuilder(SAST, getters.issueCount);

export default () => {};
