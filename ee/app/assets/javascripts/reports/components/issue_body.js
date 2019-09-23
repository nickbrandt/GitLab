import PerformanceIssueBody from 'ee/vue_merge_request_widget/components/performance_issue_body.vue';
import CodequalityIssueBody from 'ee/vue_merge_request_widget/components/codequality_issue_body.vue';
import BlockingMergeRequestsBody from 'ee/vue_merge_request_widget/components/blocking_merge_requests/blocking_merge_request_body.vue';
import LicenseIssueBody from 'ee/vue_shared/license_management/components/license_issue_body.vue';
import SastIssueBody from 'ee/vue_shared/security_reports/components/sast_issue_body.vue';
import SastContainerIssueBody from 'ee/vue_shared/security_reports/components/sast_container_issue_body.vue';
import DastIssueBody from 'ee/vue_shared/security_reports/components/dast_issue_body.vue';
import MetricsReportsIssueBody from 'ee/vue_shared/metrics_reports/components/metrics_reports_issue_body.vue';
import {
  components as componentsCE,
  componentNames as componentNamesCE,
} from '~/reports/components/issue_body';

export const components = {
  ...componentsCE,
  PerformanceIssueBody,
  CodequalityIssueBody,
  LicenseIssueBody,
  SastContainerIssueBody,
  SastIssueBody,
  DastIssueBody,
  MetricsReportsIssueBody,
  BlockingMergeRequestsBody,
};

export const componentNames = {
  ...componentNamesCE,
  PerformanceIssueBody: PerformanceIssueBody.name,
  CodequalityIssueBody: CodequalityIssueBody.name,
  LicenseIssueBody: LicenseIssueBody.name,
  SastContainerIssueBody: SastContainerIssueBody.name,
  SastIssueBody: SastIssueBody.name,
  DastIssueBody: DastIssueBody.name,
  MetricsReportsIssueBody: MetricsReportsIssueBody.name,
  BlockingMergeRequestsBody: BlockingMergeRequestsBody.name,
};
