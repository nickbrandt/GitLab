export const generateVulnerabilities = () => [
  {
    id: 'id_0',
    title: 'Vulnerability 1',
    severity: 'critical',
    state: 'dismissed',
  },
  {
    id: 'id_1',
    title: 'Vulnerability 2',
    severity: 'high',
    state: 'opened',
  },
];

export const vulnerabilities = generateVulnerabilities();
