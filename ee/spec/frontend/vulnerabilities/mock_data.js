export const generateVulnerabilities = () => [
  {
    id: 'id_0',
    title: 'Vulnerability 1',
    severity: 'critical',
    state: 'dismissed',
    location: JSON.stringify({
      image:
        'registry.gitlab.com/groulot/container-scanning-test/master:5f21de6956aee99ddb68ae49498662d9872f50ff',
    }),
    project: {
      nameWithNamespace: 'Administrator / Security reports',
    },
  },
  {
    id: 'id_1',
    title: 'Vulnerability 2',
    severity: 'high',
    state: 'opened',
    location: JSON.stringify({
      file: 'src/main/java/com/gitlab/security_products/tests/App.java',
    }),
    project: {
      nameWithNamespace: 'Administrator / Vulnerability reports',
    },
  },
];

export const vulnerabilities = generateVulnerabilities();
