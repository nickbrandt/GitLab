export const isDependenciesList = data => Array.isArray(data) && data.length > 0;

export const hasReportStatus = data => Boolean(data && typeof data.report_status === 'string');
