import { s__ } from '~/locale';

export default () => ({
  isLoadingVulnerabilities: true,
  errorLoadingVulnerabilities: false,
  isLoadingVulnerabilitiesCount: true,
  errorLoadingVulnerabilitiesCount: false,
  pageInfo: {},
  vulnerabilities: [],
  vulnerabilitiesCount: {},
  vulnerabilitiesCountEndpoint: null,
  vulnerabilitiesEndpoint: null,
  activeVulnerability: null,
  modal: {
    data: {
      description: { text: s__('Vulnerability|Description') },
      project: {
        text: s__('Vulnerability|Project'),
        isLink: true,
      },
      file: { text: s__('Vulnerability|File') },
      identifiers: { text: s__('Vulnerability|Identifiers') },
      severity: { text: s__('Vulnerability|Severity') },
      confidence: { text: s__('Vulnerability|Confidence') },
      solution: { text: s__('Vulnerability|Solution') },
      links: { text: s__('Vulnerability|Links') },
      instances: { text: s__('Vulnerability|Instances') },
    },
    vulnerability: {},
    isCreatingNewIssue: false,
    isDismissingVulnerability: false,
  },
  isCreatingIssue: false,
  isDismissingVulnerability: false,
});
