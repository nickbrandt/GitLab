import * as mockData from '../../../frontend/vue_shared/security_reports/mock_data';

// This is done to help keep the mock data across testing suites in sync.
// https://gitlab.com/gitlab-org/gitlab/merge_requests/10466#note_156218753

export const {
  dockerReportParsed,
  parsedDast,
  sastParsedIssues,
  secretScanningParsedIssues,
  sastDiffSuccessMock,
  dastDiffSuccessMock,
  containerScanningDiffSuccessMock,
  dependencyScanningDiffSuccessMock,
  secretScanningDiffSuccessMock,
} = mockData;
