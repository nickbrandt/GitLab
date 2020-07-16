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

// Browser Performance Testing
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

// Load Performance Testing
export const headLoadPerformance = {
  metrics: {
    checks: {
      fails: 0,
      passes: 45,
      value: 0,
    },
    http_req_waiting: {
      avg: 104.3543911111111,
      max: 247.8693,
      med: 99.1985,
      min: 98.1397,
      'p(90)': 100.60016,
      'p(95)': 125.45588000000023,
    },
    http_reqs: {
      count: 45,
      rate: 8.999484329547917,
    },
  },
};

export const baseLoadPerformance = {
  metrics: {
    checks: {
      fails: 0,
      passes: 39,
      value: 0,
    },
    http_req_waiting: {
      avg: 118.28965641025643,
      max: 674.4383,
      med: 98.2503,
      min: 97.1357,
      'p(90)': 104.09862000000001,
      'p(95)': 101.22848,
    },
    http_reqs: {
      count: 39,
      rate: 7.799590989448514,
    },
  },
};

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
