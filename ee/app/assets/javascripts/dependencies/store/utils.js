export const hasDependencyList = ({ dependencies }) => Array.isArray(dependencies);

export const hasReportStatus = ({ report }) => Boolean(report && typeof report.status === 'string');

export const isValidResponse = ({ data }) =>
  Boolean(data && hasDependencyList(data) && hasReportStatus(data));
