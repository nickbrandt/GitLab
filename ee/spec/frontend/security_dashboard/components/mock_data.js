export const generateVulnerabilities = () => [
  {
    id: 'id_0',
    identifiers: [
      {
        externalType: 'cve',
        name: 'CVE-2018-1234',
      },
      {
        externalType: 'gemnasium',
        name: 'Gemnasium-2018-1234',
      },
    ],
    title: 'Vulnerability 0',
    severity: 'critical',
    state: 'dismissed',
    reportType: 'SAST',
    location: {
      image:
        'registry.gitlab.com/groulot/container-scanning-test/master:5f21de6956aee99ddb68ae49498662d9872f50ff',
    },
    project: {
      nameWithNamespace: 'Administrator / Security reports',
    },
    scanner: {
      vendor: 'GitLab',
    },
  },
  {
    id: 'id_1',
    identifiers: [
      {
        externalType: 'gemnasium',
        name: 'Gemnasium-2018-1234',
      },
    ],
    title: 'Vulnerability 1',
    severity: 'high',
    state: 'opened',
    reportType: 'DEPENDENCY_SCANNING',
    location: {
      file: 'src/main/java/com/gitlab/security_products/tests/App.java',
      startLine: '1337',
    },
    project: {
      nameWithNamespace: 'Administrator / Vulnerability reports',
    },
    scanner: {
      vendor: 'GitLab',
    },
  },
  {
    id: 'id_2',
    title: 'Vulnerability 2',
    severity: 'high',
    state: 'opened',
    reportType: 'CUSTOM_SCANNER_WITHOUT_TRANSLATION',
    location: {
      file: 'src/main/java/com/gitlab/security_products/tests/App.java',
    },
    project: {
      nameWithNamespace: 'Mixed Vulnerabilities / Dependency List Test 01',
    },
    scanner: {
      vendor: 'My Custom Scanner',
    },
  },
  {
    id: 'id_3',
    title: 'Vulnerability 3',
    severity: 'high',
    state: 'opened',
    location: {
      file: 'yarn.lock',
    },
    project: {
      nameWithNamespace: 'Mixed Vulnerabilities / Rails App',
    },
    scanner: {},
  },
  {
    id: 'id_4',
    title: 'Vulnerability 4',
    severity: 'critical',
    state: 'dismissed',
    location: {},
    project: {
      nameWithNamespace: 'Administrator / Security reports',
    },
    scanner: {},
  },
];

export const vulnerabilities = generateVulnerabilities();
