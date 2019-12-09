import mockData, { mockStore } from 'spec/vue_mr_widget/mock_data';

export default Object.assign({}, mockData, {
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
    sast: true,
    container_scanning: false,
    dast: true,
    dependency_scanning: false,
    license_management: true,
  },
});

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
    name: 'Insecure Dependency',
    path: 'Gemfile.lock',
    line: 21,
    urlPath: 'basePath/Gemfile.lock#L21',
  },
];

export const headPerformance = [
  {
    subject: '/some/path',
    metrics: [
      {
        name: 'Sitespeed Score',
        value: 85,
      },
    ],
  },
  {
    subject: '/some/other/path',
    metrics: [
      {
        name: 'Sitespeed Score',
        value: 79,
        desiredSize: 'larger',
      },
      {
        name: 'Requests',
        value: 3,
        desiredSize: 'smaller',
      },
    ],
  },
  {
    subject: '/yet/another/path',
    metrics: [
      {
        name: 'Sitespeed Score',
        value: 80,
      },
    ],
  },
];

export const basePerformance = [
  {
    subject: '/some/path',
    metrics: [
      {
        name: 'Sitespeed Score',
        value: 84,
      },
    ],
  },
  {
    subject: '/some/other/path',
    metrics: [
      {
        name: 'Sitespeed Score',
        value: 80,
        desiredSize: 'larger',
      },
      {
        name: 'Requests',
        value: 4,
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
