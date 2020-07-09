import mockData, { mockStore } from 'jest/vue_mr_widget/mock_data';

export default {
  ...mockData,
  codeclimate: {
    head_path: 'head.json',
    base_path: 'base.json',
  },
  blob_path: {
    base_path: 'blob_path',
    head_path: 'blob_path',
  },
  vulnerability_feedback_help_path: '/help/user/application_security/index',
  enabled_reports: {
    sast: false,
    container_scanning: false,
    dast: false,
    dependency_scanning: false,
    license_management: false,
    secret_scanning: false,
  },
};

// Codeclimate
export const headIssues = [
  {
    check_name: 'Rubocop/Lint/UselessAssignment',
    description: 'Insecure Dependency',
    location: {
      path: 'lib/six.rb',
      lines: {
        begin: 6,
        end: 7,
      },
    },
    fingerprint: 'e879dd9bbc0953cad5037cde7ff0f627',
  },
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 22,
        end: 22,
      },
    },
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
  },
];
// Codeclimate
export const parsedHeadIssues = [
  {
    ...headIssues[1],
    name: 'Insecure Dependency',
    path: 'lib/six.rb',
    urlPath: 'headPath/lib/six.rb#L6',
    line: 6,
  },
];

export const baseIssues = [
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 22,
        end: 22,
      },
    },
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
  },
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 21,
        end: 21,
      },
    },
    fingerprint: 'ca2354534dee94ae60ba2f54e3857c50e5',
  },
];

export const parsedBaseIssues = [
  {
    ...baseIssues[1],
    name: 'Insecure Dependency',
    path: 'Gemfile.lock',
    line: 21,
    urlPath: 'basePath/Gemfile.lock#L21',
  },
];

export const headBrowserPerformance = [
  {
    subject: '/some/path',
    metrics: [
      {
        name: 'Total Score',
        value: 80,
        desiredSize: 'larger',
      },
      {
        name: 'Requests',
        value: 30,
        desiredSize: 'smaller',
      },
      {
        name: 'Speed Index',
        value: 1155,
        desiredSize: 'smaller',
      },
      {
        name: 'Transfer Size (KB)',
        value: '1070.1',
        desiredSize: 'smaller',
      },
    ],
  },
];

export const baseBrowserPerformance = [
  {
    subject: '/some/path',
    metrics: [
      {
        name: 'Total Score',
        value: 82,
        desiredSize: 'larger',
      },
      {
        name: 'Requests',
        value: 30,
        desiredSize: 'smaller',
      },
      {
        name: 'Speed Index',
        value: 1165,
        desiredSize: 'smaller',
      },
      {
        name: 'Transfer Size (KB)',
        value: '1065.1',
        desiredSize: 'smaller',
      },
    ],
  },
];

export const codequalityParsedIssues = [
  {
    name: 'Insecure Dependency',
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
    path: 'Gemfile.lock',
    line: 12,
    urlPath: 'foo/Gemfile.lock',
  },
];

export { mockStore };
