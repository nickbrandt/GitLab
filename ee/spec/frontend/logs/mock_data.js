export const mockProjectPath = 'root/autodevops-deploy';
export const mockEnvName = 'production';
export const mockEnvironmentsEndpoint = `${mockProjectPath}/environments.json`;
export const mockEnvId = '99';

const makeMockEnvironment = (id, name) => ({
  id,
  logs_path: `${mockProjectPath}/environments/${id}/logs`,
  name,
});

export const mockEnvironment = makeMockEnvironment(mockEnvId, mockEnvName);
export const mockEnvironments = [
  mockEnvironment,
  makeMockEnvironment(101, 'staging'),
  makeMockEnvironment(102, 'review/a-feature'),
];

export const mockPodName = 'production-764c58d697-aaaaa';
export const mockPods = [
  mockPodName,
  'production-764c58d697-bbbbb',
  'production-764c58d697-ccccc',
  'production-764c58d697-ddddd',
];

export const mockLines = [
  '10.36.0.1 - - [16/Oct/2019:06:29:48 UTC] "GET / HTTP/1.1" 200 13',
  '- -> /',
  '10.36.0.1 - - [16/Oct/2019:06:29:57 UTC] "GET / HTTP/1.1" 200 13',
  '- -> /',
  '10.36.0.1 - - [16/Oct/2019:06:29:58 UTC] "GET / HTTP/1.1" 200 13',
  '- -> /',
  '10.36.0.1 - - [16/Oct/2019:06:30:07 UTC] "GET / HTTP/1.1" 200 13',
  '- -> /',
  '10.36.0.1 - - [16/Oct/2019:06:30:08 UTC] "GET / HTTP/1.1" 200 13',
  '- -> /',
  '10.36.0.1 - - [16/Oct/2019:06:30:17 UTC] "GET / HTTP/1.1" 200 13',
  '- -> /',
  '10.36.0.1 - - [16/Oct/2019:06:30:18 UTC] "GET / HTTP/1.1" 200 13',
  '- -> /',
];
