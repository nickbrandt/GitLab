import { __, s__ } from '~/locale';

export default () => ({
  blobPath: {
    head: null,
    base: null,
  },

  sourceBranch: null,
  vulnerabilityFeedbackPath: null,
  vulnerabilityFeedbackHelpPath: null,
  createVulnerabilityFeedbackIssuePath: null,
  createVulnerabilityFeedbackMergeRequestPath: null,
  createVulnerabilityFeedbackDismissalPath: null,
  pipelineId: null,
  canCreateIssuePermission: false,
  canCreateFeedbackPermission: false,

  containerScanning: {
    paths: {
      head: null,
      base: null,
      diffEndpoint: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    baseReportOutofDate: false,
    hasBaseReport: false,
  },
  dast: {
    paths: {
      head: null,
      base: null,
      diffEndpoint: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    baseReportOutofDate: false,
    hasBaseReport: false,
  },

  dependencyScanning: {
    paths: {
      head: null,
      base: null,
      diffEndpoint: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    allIssues: [],
    baseReportOutofDate: false,
    hasBaseReport: false,
  },

  modal: {
    title: null,

    learnMoreUrl: null,

    vulnerability: {
      isDismissed: false,
      hasIssue: false,
      hasMergeRequest: false,
    },

    isCreatingNewIssue: false,
    isDismissingVulnerability: false,
    isShowingDeleteButtons: false,
    isCommentingOnDismissal: false,
    error: null,
  },
});
