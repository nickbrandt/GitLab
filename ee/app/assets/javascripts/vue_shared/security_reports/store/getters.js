import { s__, sprintf } from '~/locale';
import { countIssues, groupedTextBuilder, statusIcon, groupedReportText } from './utils';
import { LOADING, ERROR, SUCCESS } from './constants';
import messages from './messages';

export const groupedSastContainerText = ({ sastContainer }) =>
  groupedReportText(
    sastContainer,
    messages.CONTAINER_SCANNING,
    messages.CONTAINER_SCANNING_HAS_ERROR,
    messages.CONTAINER_SCANNING_IS_LOADING,
  );

export const groupedDastText = ({ dast }) =>
  groupedReportText(dast, messages.DAST, messages.DAST_HAS_ERROR, messages.DAST_IS_LOADING);

export const groupedDependencyText = ({ dependencyScanning }) =>
  groupedReportText(
    dependencyScanning,
    messages.DEPENDENCY_SCANNING,
    messages.DEPENDENCY_SCANNING_HAS_ERROR,
    messages.DEPENDENCY_SCANNING_IS_LOADING,
  );

export const summaryCounts = state =>
  [state.sast, state.sastContainer, state.dast, state.dependencyScanning].reduce(
    (acc, report) => {
      const curr = countIssues(report);
      acc.added += curr.added;
      acc.dismissed += curr.dismissed;
      acc.fixed += curr.fixed;
      acc.existing += curr.existing;
      return acc;
    },
    { added: 0, dismissed: 0, fixed: 0, existing: 0 },
  );

export const groupedSummaryText = (state, getters) => {
  const reportType = s__('ciReport|Security scanning');

  // All reports are loading
  if (getters.areAllReportsLoading) {
    return sprintf(messages.TRANSLATION_IS_LOADING, { reportType });
  }

  // All reports returned error
  if (getters.allReportsHaveError) {
    return s__('ciReport|Security scanning failed loading any results');
  }

  const { added, fixed, existing, dismissed } = getters.summaryCounts;

  let status = '';

  if (getters.areReportsLoading && getters.anyReportHasError) {
    status = s__('ciReport|(is loading, errors when loading results)');
  } else if (getters.areReportsLoading && !getters.anyReportHasError) {
    status = s__('ciReport|(is loading)');
  } else if (!getters.areReportsLoading && getters.anyReportHasError) {
    status = s__('ciReport|(errors when loading results)');
  }

  /*
   In order to correct wording, we ne to set the base property to true,
   if at least one report has a base.
   */
  const paths = { head: true, base: !getters.noBaseInAllReports };

  return groupedTextBuilder({ reportType, paths, added, fixed, existing, dismissed, status });
};

export const summaryStatus = (state, getters) => {
  if (getters.areReportsLoading) {
    return LOADING;
  }

  if (getters.anyReportHasError || getters.anyReportHasIssues) {
    return ERROR;
  }

  return SUCCESS;
};

export const sastContainerStatusIcon = ({ sastContainer }) =>
  statusIcon(sastContainer.isLoading, sastContainer.hasError, sastContainer.newIssues.length);

export const dastStatusIcon = ({ dast }) =>
  statusIcon(dast.isLoading, dast.hasError, dast.newIssues.length);

export const dependencyScanningStatusIcon = ({ dependencyScanning }) =>
  statusIcon(
    dependencyScanning.isLoading,
    dependencyScanning.hasError,
    dependencyScanning.newIssues.length,
  );

export const areReportsLoading = state =>
  state.sast.isLoading ||
  state.dast.isLoading ||
  state.sastContainer.isLoading ||
  state.dependencyScanning.isLoading;

export const areAllReportsLoading = state =>
  state.sast.isLoading &&
  state.dast.isLoading &&
  state.sastContainer.isLoading &&
  state.dependencyScanning.isLoading;

export const allReportsHaveError = state =>
  state.sast.hasError &&
  state.dast.hasError &&
  state.sastContainer.hasError &&
  state.dependencyScanning.hasError;

export const anyReportHasError = state =>
  state.sast.hasError ||
  state.dast.hasError ||
  state.sastContainer.hasError ||
  state.dependencyScanning.hasError;

export const noBaseInAllReports = state =>
  !state.sast.paths.base &&
  !state.dast.paths.base &&
  !state.sastContainer.paths.base &&
  !state.dependencyScanning.paths.base;

export const anyReportHasIssues = state =>
  state.sast.newIssues.length > 0 ||
  state.dast.newIssues.length > 0 ||
  state.sastContainer.newIssues.length > 0 ||
  state.dependencyScanning.newIssues.length > 0;

export const isBaseSecurityReportOutOfDate = state =>
  state.sast.baseReportOutofDate ||
  state.dast.baseReportOutofDate ||
  state.sastContainer.baseReportOutofDate ||
  state.dependencyScanning.baseReportOutofDate;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
