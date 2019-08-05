import {
  DEPENDENCY_SCANNING,
  DEPENDENCY_SCANNING_HAS_ERROR,
  DEPENDENCY_SCANNING_IS_LOADING,
} from './constants';
import { groupedReportText, statusIcon } from '../../utils';

export const groupedDependencyText = state =>
  groupedReportText(
    state,
    DEPENDENCY_SCANNING,
    DEPENDENCY_SCANNING_HAS_ERROR,
    DEPENDENCY_SCANNING_IS_LOADING,
  );

export const dependencyScanningStatusIcon = ({ isLoading, hasError, newIssues }) =>
  statusIcon(isLoading, hasError, newIssues.length);

export default () => {};
