import { REPORT_STATUS } from './constants';

export const hasDependencyList = ({ dependencies }) => Array.isArray(dependencies);

export const hasReportStatus = ({ report }) =>
  Boolean(report && Object.values(REPORT_STATUS).includes(report.status));

export const isValidResponse = ({ data }) =>
  Boolean(data && hasDependencyList(data) && hasReportStatus(data));
