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

  sastContainer: {
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
  },

  modal: {
    title: null,

    // Dynamic data rendered for each issue
    data: {
      description: {
        value: null,
        text: s__('ciReport|Description'),
        isLink: false,
      },
      url: {
        value: null,
        url: null,
        text: __('URL'),
        isLink: true,
      },
      file: {
        value: null,
        url: null,
        text: s__('ciReport|File'),
        isLink: true,
      },
      identifiers: {
        value: [],
        text: s__('ciReport|Identifiers'),
        isLink: false,
      },
      severity: {
        value: null,
        text: s__('ciReport|Severity'),
        isLink: false,
      },
      confidence: {
        value: null,
        text: s__('ciReport|Confidence'),
        isLink: false,
      },
      className: {
        value: null,
        text: s__('ciReport|Class'),
        isLink: false,
      },
      methodName: {
        value: null,
        text: s__('ciReport|Method'),
        isLink: false,
      },
      image: {
        value: null,
        text: s__('ciReport|Image'),
        isLink: false,
      },
      namespace: {
        value: null,
        text: s__('ciReport|Namespace'),
        isLink: false,
      },
      links: {
        value: [],
        text: s__('ciReport|Links'),
        isLink: false,
      },
      instances: {
        value: [],
        text: s__('ciReport|Instances'),
        isLink: false,
      },
    },
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
