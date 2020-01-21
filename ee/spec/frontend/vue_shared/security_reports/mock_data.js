const libTiffCveFingerprint2 = '29af456d1107381bc2511646e2ae488ddfe9a8ed';

export const sastParsedIssues = [
  {
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    line: 12,
    priority: 'High',
    urlPath: 'foo/Gemfile.lock',
  },
];

export const sastIssues = [
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Arbitrary file existence disclosure in Action Pack',
    cve: 'CVE-2014-7829',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
      end_line: 10,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2014-7829',
        value: 'CVE-2014-7829',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-7829',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Possible Information Leak Vulnerability in Action View',
    cve: 'CVE-2016-0752',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0752',
        value: 'CVE-2016-0752',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0752',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    cve: 'CVE-2016-0751',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0751',
        value: 'CVE-2016-0751',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0751',
      },
    ],
  },
];

export const sastIssuesBase = [
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Test Information Leak Vulnerability in Action View',
    cve: 'CVE-2016-9999',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
      end_line: 10,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-9999',
        value: 'CVE-2016-9999',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-9999',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    category: 'sast',
    message: 'Possible Information Leak Vulnerability in Action View',
    cve: 'CVE-2016-0752',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    location: {
      file: 'Gemfile.lock',
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
    identifiers: [
      {
        type: 'CVE',
        name: 'CVE-2016-0752',
        value: 'CVE-2016-0752',
        link: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0752',
      },
    ],
  },
];

export const dependencyScanningIssuesOld = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    line: '5',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
];

export const dependencyScanningIssues = [
  {
    category: 'dependency_scanning',
    message: 'ruby-ffi DDL loading issue on Windows OS',
    cve: 'sast-sample-rails/Gemfile.lock:ffi:cve:CVE-2018-1000201',
    severity: 'High',
    solution: 'upgrade to \u003e= 1.9.24',
    scanner: {
      id: 'bundler_audit',
      name: 'bundler-audit',
    },
    location: {
      file: 'sast-sample-rails/Gemfile.lock',
      dependency: {
        package: {
          name: 'ffi',
        },
        version: '1.9.18',
      },
    },
    identifiers: [
      {
        type: 'cve',
        name: 'CVE-2018-1000201',
        value: 'CVE-2018-1000201',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-1000201',
      },
    ],
    links: [
      {
        url: 'https://github.com/ffi/ffi/releases/tag/1.9.24',
      },
    ],
  },
  {
    category: 'dependency_scanning',
    message: 'XSS vulnerability in rails-html-sanitizer',
    cve: 'sast-sample-rails/Gemfile.lock:rails-html-sanitizer:cve:CVE-2018-3741',
    severity: 'Unknown',
    solution: 'upgrade to \u003e= 1.0.4',
    scanner: {
      id: 'bundler_audit',
      name: 'bundler-audit',
    },
    location: {
      file: 'sast-sample-rails/Gemfile.lock',
      dependency: {
        package: {
          name: 'rails-html-sanitizer',
        },
        version: '1.0.3',
      },
    },
    identifiers: [
      {
        type: 'cve',
        name: 'CVE-2018-3741',
        value: 'CVE-2018-3741',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-3741',
      },
    ],
    links: [
      {
        url: 'https://groups.google.com/d/msg/rubyonrails-security/tP7W3kLc5u4/uDy2Br7xBgAJ',
      },
    ],
  },
  {
    category: 'dependency_scanning',
    message: 'Vulnerability in ansi2html',
    cve: ':ansi2html:npm:51',
    severity: 'High',
    scanner: {
      id: 'retire.js',
      name: 'Retire.js',
    },
    location: {
      dependency: {
        package: {
          name: 'ansi2html',
        },
        version: '0.0.1',
      },
    },
    identifiers: [
      {
        type: 'npm',
        name: 'NPM-51',
        value: '51',
        url: 'https://www.npmjs.com/advisories/51',
      },
    ],
    links: [
      {
        url: 'https://nodesecurity.io/advisories/51',
      },
    ],
  },
];

export const dependencyScanningIssuesMajor2 = {
  version: '2.0',
  vulnerabilities: dependencyScanningIssues,
  remediations: [
    {
      fixes: [{ cve: dependencyScanningIssues[0].cve }],
      summary: 'Fixes the first dependency Scanning issue',
    },
  ],
};

export const dependencyScanningIssuesBase = [
  {
    tool: 'bundler_audit',
    message: 'Test Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-9999',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
];

export const parsedDependencyScanningIssuesStore = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    line: '5',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock#L5',
    category: 'dependency_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Information Leak Vulnerability in Action View',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'dependency_scanning',
    project_fingerprint: 'a6b61a2eba59071178d5899b26dd699fb880de1e',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: undefined,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Object Leak and Denial of Service attack in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'dependency_scanning',
    project_fingerprint: '830f85e5fb011408bab365eb809cd97a45b0aa17',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: undefined,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
      },
    ],
  },
];

export const parsedDependencyScanningIssuesHead = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    line: '5',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock#L5',
    category: 'dependency_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: 5,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      },
    ],
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    title: 'Possible Object Leak and Denial of Service attack in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'dependency_scanning',
    project_fingerprint: '830f85e5fb011408bab365eb809cd97a45b0aa17',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: undefined,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
      },
    ],
  },
];

export const parsedDependencyScanningBaseStore = [
  {
    title: 'Test Information Leak Vulnerability in Action View',
    tool: 'bundler_audit',
    message: 'Test Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-9999',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
    category: 'dependency_scanning',
    project_fingerprint: '3f5608c99f0c7442ba59bc6c0c1864d0000f8e1a',
    remediations: [],
    location: {
      file: 'Gemfile.lock',
      start_line: undefined,
    },
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      },
    ],
  },
];

export const dockerReportParsed = {
  unapproved: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
      title: 'CVE-2017-12944',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-12944',
          value: 'CVE-2017-12944',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-12944',
        },
      ],
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
      title: 'CVE-2017-16232',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-16232',
          value: 'CVE-2017-16232',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
        },
      ],
    },
  ],
  approved: [
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
      title: 'CVE-2014-8130',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-8130',
          value: 'CVE-2017-8130',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8130',
        },
      ],
    },
  ],
  vulnerabilities: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
      title: 'CVE-2017-12944',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-12944',
          value: 'CVE-2017-12944',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-v',
        },
      ],
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
      title: 'CVE-2017-16232',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-16232',
          value: 'CVE-2017-16232',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
        },
      ],
    },
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
      title: 'CVE-2014-8130',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-8130',
          value: 'CVE-2017-8130',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8130',
        },
      ],
    },
  ],
};

export const parsedDast = [
  {
    category: 'dast',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
    name: 'Absence of Anti-CSRF Tokens',
    title: 'Absence of Anti-CSRF Tokens',
    riskcode: '1',
    riskdesc: 'Low (Medium)',
    severity: 'Low',
    confidence: 'Medium',
    cweid: '3',
    desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
    pluginid: '123',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-3',
        value: '3',
        url: 'https://cwe.mitre.org/data/definitions/3.html',
      },
    ],
    instances: [
      {
        uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
        method: 'GET',
        evidence: "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
      },
      {
        uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
        method: 'GET',
        evidence: "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
      },
    ],
    solution: ' Update to latest ',
    description: ' No Anti-CSRF tokens were found in a HTML submission form. ',
  },
  {
    category: 'dast',
    project_fingerprint: 'ae8fe380dd9aa5a7a956d9085fe7cf6b87d0d028',
    alert: 'X-Content-Type-Options Header Missing',
    name: 'X-Content-Type-Options Header Missing',
    title: 'X-Content-Type-Options Header Missing',
    riskdesc: 'Low (Medium)',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-4',
        value: '4',
        url: 'https://cwe.mitre.org/data/definitions/4.html',
      },
    ],
    severity: 'Low',
    confidence: 'Medium',
    cweid: '4',
    desc: '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
    pluginid: '3456',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
        method: 'GET',
        param: 'X-Content-Type-Options',
      },
    ],
    solution: ' Update to latest ',
    description: ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
  },
];

export const sastFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'sast',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'sast',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
];

export const dependencyScanningFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'dependency_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'dependency_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
];

export const dastFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
  },
];

export const containerScanningFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: libTiffCveFingerprint2,
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: libTiffCveFingerprint2,
  },
];

export const mockFindings = [
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Cross-site Scripting in serialize-javascript',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: { external_id: 'gemnasium', name: 'Gemnasium' },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '58caa017-9a9a-46d6-bab2-ec930f46833c',
        name: 'Gemnasium-58caa017-9a9a-46d6-bab2-ec930f46833c',
        url:
          'https://deps.sec.gitlab.com/packages/npm/serialize-javascript/versions/1.7.0/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-16769',
        name: 'CVE-2019-16769',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16769',
      },
    ],
    project_fingerprint: '09df9f4d11c8deb93d81bdcc39f7667b44143298',
    create_vulnerability_feedback_issue_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    project: {
      id: 7071551,
      name: 'gitlab-ui',
      full_path: '/gitlab-org/gitlab-ui',
      full_name: 'GitLab.org / gitlab-ui',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'The serialize-javascript npm package is vulnerable to Cross-site Scripting (XSS). It does not properly mitigate against unsafe characters in serialized regular expressions. If serialized data of regular expression objects are used in an environment other than Node.js, it is affected by this vulnerability.',
    links: [{ url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-16769' }],
    location: {
      file: 'yarn.lock',
      dependency: { package: { name: 'serialize-javascript' }, version: '1.7.0' },
    },
    remediations: [null],
    solution: 'Upgrade to version 2.1.1 or above.',
    state: 'opened',
    blob_path: '/gitlab-org/gitlab-ui/blob/ad137f0a8ac59af961afe47d04e5cc062c6864a9/yarn.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: '3rd party CORS request may execute in jquery',
    severity: 'medium',
    confidence: 'undefined',
    scanner: { external_id: 'retire.js', name: 'Retire.js' },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2015-9251',
        name: 'CVE-2015-9251',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-9251',
      },
    ],
    project_fingerprint: '1ecd3b214cf39c0b9ad23a0a9679778d7cf55876',
    create_vulnerability_feedback_issue_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    project: {
      id: 7071551,
      name: 'gitlab-ui',
      full_path: '/gitlab-org/gitlab-ui',
      full_name: 'GitLab.org / gitlab-ui',
    },
    dismissal_feedback: {
      id: 2528,
      created_at: '2019-08-26T12:30:32.349Z',
      project_id: 7071551,
      author: {
        id: 181229,
        name: "Lukas 'Eipi' Eipert",
        username: 'leipert',
        state: 'active',
        avatar_url:
          'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
        web_url: 'https://gitlab.com/leipert',
        status_tooltip_html: null,
        path: '/leipert',
      },
      comment_details: {
        comment: 'This particular jQuery version appears in a test path of tinycolor2.\n',
        comment_timestamp: '2019-08-26T12:30:37.610Z',
        comment_author: {
          id: 181229,
          name: "Lukas 'Eipi' Eipert",
          username: 'leipert',
          state: 'active',
          avatar_url:
            'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
          web_url: 'https://gitlab.com/leipert',
          status_tooltip_html: null,
          path: '/leipert',
        },
      },
      pipeline: { id: 78375355, path: '/gitlab-org/gitlab-ui/pipelines/78375355' },
      destroy_vulnerability_feedback_dismissal_path:
        '/gitlab-org/gitlab-ui/vulnerability_feedback/2528',
      category: 'dependency_scanning',
      feedback_type: 'dismissal',
      branch: 'leipert-dogfood-secure',
      project_fingerprint: '1ecd3b214cf39c0b9ad23a0a9679778d7cf55876',
    },
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      { url: 'https://github.com/jquery/jquery/issues/2432' },
      { url: 'http://blog.jquery.com/2016/01/08/jquery-2-2-and-1-12-released/' },
      { url: 'https://nvd.nist.gov/vuln/detail/CVE-2015-9251' },
      { url: 'http://research.insecurelabs.org/jquery/test/' },
    ],
    location: {
      file: 'node_modules/tinycolor2/demo/jquery-1.9.1.js',
      dependency: { package: { name: 'jquery' }, version: '1.9.1' },
    },
    remediations: [null],
    solution: null,
    state: 'dismissed',
    blob_path:
      '/gitlab-org/gitlab-ui/blob/ad137f0a8ac59af961afe47d04e5cc062c6864a9/node_modules/tinycolor2/demo/jquery-1.9.1.js',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name:
      'jQuery before 3.4.0, as used in Drupal, Backdrop CMS, and other products, mishandles jQuery.extend(true, {}, ...) because of Object.prototype pollution in jquery',
    severity: 'low',
    confidence: 'undefined',
    scanner: { external_id: 'retire.js', name: 'Retire.js' },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-11358',
        name: 'CVE-2019-11358',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-11358',
      },
    ],
    project_fingerprint: 'aeb4b2442d92d0ccf7023f0c220bda8b4ba910e3',
    create_vulnerability_feedback_issue_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    project: {
      id: 7071551,
      name: 'gitlab-ui',
      full_path: '/gitlab-org/gitlab-ui',
      full_name: 'GitLab.org / gitlab-ui',
    },
    dismissal_feedback: {
      id: 4197,
      created_at: '2019-11-14T11:03:18.472Z',
      project_id: 7071551,
      author: {
        id: 181229,
        name: "Lukas 'Eipi' Eipert",
        username: 'leipert',
        state: 'active',
        avatar_url:
          'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
        web_url: 'https://gitlab.com/leipert',
        status_tooltip_html: null,
        path: '/leipert',
      },
      comment_details: {
        comment:
          'This is a false positive, as it just part of some documentation assets of sass-true.',
        comment_timestamp: '2019-11-14T11:03:18.464Z',
        comment_author: {
          id: 181229,
          name: "Lukas 'Eipi' Eipert",
          username: 'leipert',
          state: 'active',
          avatar_url:
            'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
          web_url: 'https://gitlab.com/leipert',
          status_tooltip_html: null,
          path: '/leipert',
        },
      },
      destroy_vulnerability_feedback_dismissal_path:
        '/gitlab-org/gitlab-ui/vulnerability_feedback/4197',
      category: 'dependency_scanning',
      feedback_type: 'dismissal',
      branch: null,
      project_fingerprint: 'aeb4b2442d92d0ccf7023f0c220bda8b4ba910e3',
    },
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      { url: 'https://blog.jquery.com/2019/04/10/jquery-3-4-0-released/' },
      { url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-11358' },
      { url: 'https://github.com/jquery/jquery/commit/753d591aea698e57d6db58c9f722cd0808619b1b' },
    ],
    location: {
      file: 'node_modules/sass-true/docs/assets/webpack/common.min.js',
      dependency: { package: { name: 'jquery' }, version: '3.3.1' },
    },
    remediations: [null],
    solution: null,
    state: 'dismissed',
    blob_path:
      '/gitlab-org/gitlab-ui/blob/ad137f0a8ac59af961afe47d04e5cc062c6864a9/node_modules/sass-true/docs/assets/webpack/common.min.js',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name:
      'jQuery before 3.4.0, as used in Drupal, Backdrop CMS, and other products, mishandles jQuery.extend(true, {}, ...) because of Object.prototype pollution in jquery',
    severity: 'low',
    confidence: 'undefined',
    scanner: { external_id: 'retire.js', name: 'Retire.js' },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-11358',
        name: 'CVE-2019-11358',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-11358',
      },
    ],
    project_fingerprint: 'eb86aa13eb9d897a083ead6e134aa78aa9cadd52',
    create_vulnerability_feedback_issue_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    project: {
      id: 7071551,
      name: 'gitlab-ui',
      full_path: '/gitlab-org/gitlab-ui',
      full_name: 'GitLab.org / gitlab-ui',
    },
    dismissal_feedback: {
      id: 2527,
      created_at: '2019-08-26T12:29:43.624Z',
      project_id: 7071551,
      author: {
        id: 181229,
        name: "Lukas 'Eipi' Eipert",
        username: 'leipert',
        state: 'active',
        avatar_url:
          'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
        web_url: 'https://gitlab.com/leipert',
        status_tooltip_html: null,
        path: '/leipert',
      },
      comment_details: {
        comment: 'This particular jQuery version appears in a test path of tinycolor2.',
        comment_timestamp: '2019-08-26T12:30:14.840Z',
        comment_author: {
          id: 181229,
          name: "Lukas 'Eipi' Eipert",
          username: 'leipert',
          state: 'active',
          avatar_url:
            'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
          web_url: 'https://gitlab.com/leipert',
          status_tooltip_html: null,
          path: '/leipert',
        },
      },
      pipeline: { id: 78375355, path: '/gitlab-org/gitlab-ui/pipelines/78375355' },
      destroy_vulnerability_feedback_dismissal_path:
        '/gitlab-org/gitlab-ui/vulnerability_feedback/2527',
      category: 'dependency_scanning',
      feedback_type: 'dismissal',
      branch: 'leipert-dogfood-secure',
      project_fingerprint: 'eb86aa13eb9d897a083ead6e134aa78aa9cadd52',
    },
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      { url: 'https://blog.jquery.com/2019/04/10/jquery-3-4-0-released/' },
      { url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-11358' },
      { url: 'https://github.com/jquery/jquery/commit/753d591aea698e57d6db58c9f722cd0808619b1b' },
    ],
    location: {
      file: 'node_modules/tinycolor2/demo/jquery-1.9.1.js',
      dependency: { package: { name: 'jquery' }, version: '1.9.1' },
    },
    remediations: [null],
    solution: null,
    state: 'dismissed',
    blob_path:
      '/gitlab-org/gitlab-ui/blob/ad137f0a8ac59af961afe47d04e5cc062c6864a9/node_modules/tinycolor2/demo/jquery-1.9.1.js',
  },
];

export const sastDiffSuccessMock = {
  added: [mockFindings[0]],
  fixed: [mockFindings[1], mockFindings[2]],
  existing: [mockFindings[3]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};

export const dastDiffSuccessMock = {
  added: [mockFindings[0]],
  fixed: [mockFindings[1], mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};

export const containerScanningDiffSuccessMock = {
  added: [mockFindings[0], mockFindings[1]],
  fixed: [mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};

export const dependencyScanningDiffSuccessMock = {
  added: [mockFindings[0], mockFindings[1]],
  fixed: [mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};
