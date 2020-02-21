export const findings = [
  // From sast_reports in
  // https://gitlab.com/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/merge_requests/11
  {
    id: null,
    report_type: 'sast',
    name: 'URLConnection Server-Side Request Forgery (SSRF) and File Disclosure',
    severity: 'medium',
    confidence: 'high',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'URLCONNECTION_SSRF_FD',
        name: 'Find Security Bugs-URLCONNECTION_SSRF_FD',
        url: 'https://find-sec-bugs.github.io/bugs.htm#URLCONNECTION_SSRF_FD',
      },
      {
        external_type: 'cwe',
        external_id: '918',
        name: 'CWE-918',
        url: 'https://cwe.mitre.org/data/definitions/918.html',
      },
    ],
    project_fingerprint: '63baf790952a1522273edf2846dfb7f6e29b5bca',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'This web server request could be used by an attacker to expose internal services and filesystem.',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/CweApi.java',
      start_line: 96,
      end_line: 96,
      class: 'com.gitlab.vulnlib.cwe918',
      method: 'vulnID00001',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/CweApi.java#L96-96',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Spring CSRF unrestricted RequestMapping',
    severity: 'medium',
    confidence: 'high',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'SPRING_CSRF_UNRESTRICTED_REQUEST_MAPPING',
        name: 'Find Security Bugs-SPRING_CSRF_UNRESTRICTED_REQUEST_MAPPING',
        url: 'https://find-sec-bugs.github.io/bugs.htm#SPRING_CSRF_UNRESTRICTED_REQUEST_MAPPING',
      },
      {
        external_type: 'cwe',
        external_id: '352',
        name: 'CWE-352',
        url: 'https://cwe.mitre.org/data/definitions/352.html',
      },
    ],
    project_fingerprint: '49842b9f4bbe1afe74b187fba6216eb4ea5e30a7',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: "Unrestricted Spring's RequestMapping makes the method vulnerable to CSRF attacks",
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/configuration/HomeController.java',
      start_line: 15,
      end_line: 15,
      class: 'org.openapitools.configuration.HomeController',
      method: 'index',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/configuration/HomeController.java#L15-15',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Potential Path Traversal (file read)',
    severity: 'medium',
    confidence: 'high',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'PATH_TRAVERSAL_IN',
        name: 'Find Security Bugs-PATH_TRAVERSAL_IN',
        url: 'https://find-sec-bugs.github.io/bugs.htm#PATH_TRAVERSAL_IN',
      },
      {
        external_type: 'cwe',
        external_id: '22',
        name: 'CWE-22',
        url: 'https://cwe.mitre.org/data/definitions/22.html',
      },
    ],
    project_fingerprint: '44023b93a1568537bc257d7481a5596b325599da',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'This API (java/nio/file/Paths.get(Ljava/lang/String;[Ljava/lang/String;)Ljava/nio/file/Path;) reads a file whose location might be specified by user input',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/CweApi.java',
      start_line: 56,
      end_line: 56,
      class: 'com.gitlab.vulnlib.cwe22',
      method: 'vulnID00001',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/CweApi.java#L56-56',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'URLConnection Server-Side Request Forgery (SSRF) and File Disclosure',
    severity: 'medium',
    confidence: 'high',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'URLCONNECTION_SSRF_FD',
        name: 'Find Security Bugs-URLCONNECTION_SSRF_FD',
        url: 'https://find-sec-bugs.github.io/bugs.htm#URLCONNECTION_SSRF_FD',
      },
      {
        external_type: 'cwe',
        external_id: '918',
        name: 'CWE-918',
        url: 'https://cwe.mitre.org/data/definitions/918.html',
      },
    ],
    project_fingerprint: '0857addea39feda14055f6d06a8aba814db28c02',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'This web server request could be used by an attacker to expose internal services and filesystem.',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/CweApi.java',
      start_line: 116,
      end_line: 116,
      class: 'com.gitlab.vulnlib.cwe918',
      method: 'vulnID00002',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/CweApi.java#L116-116',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Potential XSS in Servlet',
    severity: 'medium',
    confidence: 'medium',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'XSS_SERVLET',
        name: 'Find Security Bugs-XSS_SERVLET',
        url: 'https://find-sec-bugs.github.io/bugs.htm#XSS_SERVLET',
      },
      {
        external_type: 'cwe',
        external_id: '79',
        name: 'CWE-79',
        url: 'https://cwe.mitre.org/data/definitions/79.html',
      },
    ],
    project_fingerprint: '9da7595ecf96a5ffb9f8d315439533d093cec801',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'This use of java/io/PrintWriter.print(Ljava/lang/String;)V could be vulnerable to XSS in the Servlet',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/ApiUtil.java',
      start_line: 14,
      end_line: 14,
      class: 'org.openapitools.api.ApiUtil',
      method: 'setExampleResponse',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/ApiUtil.java#L14-14',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Found Spring endpoint',
    severity: 'low',
    confidence: 'low',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'SPRING_ENDPOINT',
        name: 'Find Security Bugs-SPRING_ENDPOINT',
        url: 'https://find-sec-bugs.github.io/bugs.htm#SPRING_ENDPOINT',
      },
    ],
    project_fingerprint: '0036fb14b378eb3edf3b9ded751b6a54de6cd3c5',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: 'org.openapitools.api.CweApi is a Spring endpoint (Controller)',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/CweApi.java',
      start_line: 76,
      end_line: 76,
      class: 'org.openapitools.api.CweApi',
      method: 'cwe79vid00001',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/CweApi.java#L76-76',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Found Spring endpoint',
    severity: 'low',
    confidence: 'low',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'SPRING_ENDPOINT',
        name: 'Find Security Bugs-SPRING_ENDPOINT',
        url: 'https://find-sec-bugs.github.io/bugs.htm#SPRING_ENDPOINT',
      },
    ],
    project_fingerprint: '478d88e684e4929e3c8350f01d22ea1de81c764c',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: 'org.openapitools.api.CweApi is a Spring endpoint (Controller)',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/CweApi.java',
      start_line: 96,
      end_line: 96,
      class: 'org.openapitools.api.CweApi',
      method: 'cwe918vid00001',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/CweApi.java#L96-96',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Found Spring endpoint',
    severity: 'low',
    confidence: 'low',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'SPRING_ENDPOINT',
        name: 'Find Security Bugs-SPRING_ENDPOINT',
        url: 'https://find-sec-bugs.github.io/bugs.htm#SPRING_ENDPOINT',
      },
    ],
    project_fingerprint: 'ae73233c6387cd71e37db995a0a04871c9265ed7',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: 'org.openapitools.api.CweApi is a Spring endpoint (Controller)',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/CweApi.java',
      start_line: 56,
      end_line: 56,
      class: 'org.openapitools.api.CweApi',
      method: 'cwe22vid00001',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/CweApi.java#L56-56',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Found Spring endpoint',
    severity: 'low',
    confidence: 'low',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'SPRING_ENDPOINT',
        name: 'Find Security Bugs-SPRING_ENDPOINT',
        url: 'https://find-sec-bugs.github.io/bugs.htm#SPRING_ENDPOINT',
      },
    ],
    project_fingerprint: 'a93b9ad79f43d665887fee1ebfcd42b722561f6d',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: 'org.openapitools.api.CweApi is a Spring endpoint (Controller)',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/CweApi.java',
      start_line: 116,
      end_line: 116,
      class: 'org.openapitools.api.CweApi',
      method: 'cwe918vid00002',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/CweApi.java#L116-116',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Potential HTTP Response Splitting',
    severity: 'low',
    confidence: 'low',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'HTTP_RESPONSE_SPLITTING',
        name: 'Find Security Bugs-HTTP_RESPONSE_SPLITTING',
        url: 'https://find-sec-bugs.github.io/bugs.htm#HTTP_RESPONSE_SPLITTING',
      },
      {
        external_type: 'cwe',
        external_id: '113',
        name: 'CWE-113',
        url: 'https://cwe.mitre.org/data/definitions/113.html',
      },
    ],
    project_fingerprint: '202004b1ebb394a41c5d1d6cc5f9832cb7d1561d',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'This use of javax/servlet/http/HttpServletResponse.addHeader(Ljava/lang/String;Ljava/lang/String;)V might be used to include CRLF characters into HTTP headers',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/api/ApiUtil.java',
      start_line: 13,
      end_line: 13,
      class: 'org.openapitools.api.ApiUtil',
      method: 'setExampleResponse',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/api/ApiUtil.java#L13-13',
  },
  {
    id: null,
    report_type: 'sast',
    name: 'Found Spring endpoint',
    severity: 'low',
    confidence: 'low',
    scanner: { external_id: 'find_sec_bugs', name: 'Find Security Bugs' },
    identifiers: [
      {
        external_type: 'find_sec_bugs_type',
        external_id: 'SPRING_ENDPOINT',
        name: 'Find Security Bugs-SPRING_ENDPOINT',
        url: 'https://find-sec-bugs.github.io/bugs.htm#SPRING_ENDPOINT',
      },
    ],
    project_fingerprint: 'd124ac04928e7809ebabb3f365456df56b404572',
    create_vulnerability_feedback_issue_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/vulnerability_feedback',
    project: {
      id: 16819248,
      name: 'java-spring-mvn',
      full_path: '/gitlab-org/security-products/benchmark-suite/java-spring-mvn',
      full_name: 'GitLab.org / security-products / Security Benchmark Suite / java-spring-mvn',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: 'org.openapitools.configuration.HomeController is a Spring endpoint (Controller)',
    links: [],
    location: {
      file: 'src/main/java/org/openapitools/configuration/HomeController.java',
      start_line: 15,
      end_line: 15,
      class: 'org.openapitools.configuration.HomeController',
      method: 'index',
      dependency: { package: {} },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/gitlab-org/security-products/benchmark-suite/java-spring-mvn/-/blob/a8896bbafbb0beae5e594fae0fd10598b58dfb37/src/main/java/org/openapitools/configuration/HomeController.java#L15-15',
  },

  // From
  // https://staging.gitlab.com/secure-team-test/dependency-list-test/-/merge_requests/3
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'ruby-ffi DDL loading issue on Windows OS',
    severity: 'high',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-1000201',
        name: 'CVE-2018-1000201',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-1000201',
      },
    ],
    project_fingerprint: 'df9269ff0842b61667d2ad9933321ef4080a86f9',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: {
      id: 362,
      created_at: '2019-08-20T05:37:11.393Z',
      project_id: 4392789,
      author: {
        id: 1675933,
        name: 'Cameron Swords',
        username: 'camswords',
        state: 'active',
        avatar_url:
          'https://secure.gravatar.com/avatar/3b729cf96bcced6384ebb94f0362bd4b?s=80&d=identicon',
        web_url: 'https://staging.gitlab.com/camswords',
        status_tooltip_html: null,
        path: '/camswords',
      },
      issue_iid: 1,
      issue_url: 'https://staging.gitlab.com/secure-team-test/dependency-list-test/issues/1',
      category: 'dependency_scanning',
      feedback_type: 'issue',
      branch: null,
      project_fingerprint: 'df9269ff0842b61667d2ad9933321ef4080a86f9',
    },
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/ffi/ffi/releases/tag/1.9.24',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'ffi',
        },
        version: '1.9.21',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.9.24',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Nokogiri Command Injection Vulnerability via Nokogiri::CSS::Tokenizer#load_file',
    severity: 'high',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-5477',
        name: 'CVE-2019-5477',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5477',
      },
    ],
    project_fingerprint: 'b76330da75be8b8115ba074ab86b37f5f1be9ed3',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/sparklemotion/nokogiri/issues/1915',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'nokogiri',
        },
        version: '1.8.2',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.10.4',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Keepalive thread overload/DoS in puma',
    severity: 'high',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-16770',
        name: 'CVE-2019-16770',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16770',
      },
    ],
    project_fingerprint: 'f9b04241ae8c356add0cb6379740e13b3ce64408',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/puma/puma/security/advisories/GHSA-7xx3-m584-x994',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'puma',
        },
        version: '3.11.2',
      },
    },
    remediations: [null],
    solution: 'upgrade to ~> 3.12.2, >= 4.3.1',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'express_no-charset-in-content-type-header in express',
    severity: 'medium',
    confidence: 'undefined',
    scanner: {
      external_id: 'retire.js',
      name: 'Retire.js',
    },
    identifiers: [
      {
        external_type: 'npm',
        external_id: '8',
        name: 'NPM-8',
        url: 'https://www.npmjs.com/advisories/8',
      },
    ],
    project_fingerprint: 'e9bd4ce64357b70957f6b248a618c49a495d18b5',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://nodesecurity.io/advisories/8',
      },
    ],
    location: {
      file: 'package.json',
      dependency: {
        package: {
          name: 'express',
        },
        version: '1.0.0',
      },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/package.json',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'XSS with location.hash in jquery',
    severity: 'medium',
    confidence: 'undefined',
    scanner: {
      external_id: 'retire.js',
      name: 'Retire.js',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2011-4969',
        name: 'CVE-2011-4969',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2011-4969',
      },
    ],
    project_fingerprint: '1aaede0b57c4cb8964ca8e6a215d143b335d7431',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2011-4969',
      },
      {
        url: 'http://research.insecurelabs.org/jquery/test/',
      },
      {
        url: 'https://bugs.jquery.com/ticket/9521',
      },
    ],
    location: {
      file: 'package.json',
      dependency: {
        package: {
          name: 'jquery',
        },
        version: '1.3.2',
      },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/package.json',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Selector interpreted as HTML in jquery',
    severity: 'medium',
    confidence: 'undefined',
    scanner: {
      external_id: 'retire.js',
      name: 'Retire.js',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2012-6708',
        name: 'CVE-2012-6708',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-6708',
      },
    ],
    project_fingerprint: '7713da93aa8e1b9772dcd68206f8611584f57c4d',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'http://bugs.jquery.com/ticket/11290',
      },
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2012-6708',
      },
      {
        url: 'http://research.insecurelabs.org/jquery/test/',
      },
    ],
    location: {
      file: 'package.json',
      dependency: {
        package: {
          name: 'jquery',
        },
        version: '1.7.2',
      },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/package.json',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: '3rd party CORS request may execute in jquery',
    severity: 'medium',
    confidence: 'undefined',
    scanner: {
      external_id: 'retire.js',
      name: 'Retire.js',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2015-9251',
        name: 'CVE-2015-9251',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-9251',
      },
    ],
    project_fingerprint: 'e25047d32cef15b08530eac3f49f3c3aeefdc88d',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/jquery/jquery/issues/2432',
      },
      {
        url: 'http://blog.jquery.com/2016/01/08/jquery-2-2-and-1-12-released/',
      },
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2015-9251',
      },
      {
        url: 'http://research.insecurelabs.org/jquery/test/',
      },
    ],
    location: {
      file: 'package.json',
      dependency: {
        package: {
          name: 'jquery',
        },
        version: '1.7.2',
      },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/package.json',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name:
      'jQuery before 3.4.0, as used in Drupal, Backdrop CMS, and other products, mishandles jQuery.extend(true, {}, ...) because of Object.prototype pollution in jquery',
    severity: 'low',
    confidence: 'undefined',
    scanner: {
      external_id: 'retire.js',
      name: 'Retire.js',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-11358',
        name: 'CVE-2019-11358',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-11358',
      },
    ],
    project_fingerprint: '4ab344e59e68a2db1982ab4d7fdc248f923483a0',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://blog.jquery.com/2019/04/10/jquery-3-4-0-released/',
      },
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-11358',
      },
      {
        url: 'https://github.com/jquery/jquery/commit/753d591aea698e57d6db58c9f722cd0808619b1b',
      },
    ],
    location: {
      file: 'package.json',
      dependency: {
        package: {
          name: 'jquery',
        },
        version: '1.3.2',
      },
    },
    remediations: [null],
    solution: null,
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/package.json',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Prototype pollution attack in lodash',
    severity: 'low',
    confidence: 'undefined',
    scanner: {
      external_id: 'retire.js',
      name: 'Retire.js',
    },
    identifiers: [
      {
        external_type: 'hackerone',
        external_id: '310443',
        name: 'HACKERONE-310443',
        url: 'https://hackerone.com/reports/310443',
      },
    ],
    project_fingerprint: 'b3e9a7c4c9c3e642073802f47cb263b72d5fc7b3',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: {
      id: 366,
      created_at: '2019-08-22T01:55:32.037Z',
      project_id: 4392789,
      author: {
        id: 1675933,
        name: 'Cameron Swords',
        username: 'camswords',
        state: 'active',
        avatar_url:
          'https://secure.gravatar.com/avatar/3b729cf96bcced6384ebb94f0362bd4b?s=80&d=identicon',
        web_url: 'https://staging.gitlab.com/camswords',
        status_tooltip_html: null,
        path: '/camswords',
      },
      comment_details: {
        comment: 'Testing dismissing a vulnerability.',
        comment_timestamp: '2019-08-22T01:55:32.028Z',
        comment_author: {
          id: 1675933,
          name: 'Cameron Swords',
          username: 'camswords',
          state: 'active',
          avatar_url:
            'https://secure.gravatar.com/avatar/3b729cf96bcced6384ebb94f0362bd4b?s=80&d=identicon',
          web_url: 'https://staging.gitlab.com/camswords',
          status_tooltip_html: null,
          path: '/camswords',
        },
      },
      destroy_vulnerability_feedback_dismissal_path:
        '/secure-team-test/dependency-list-test/-/vulnerability_feedback/366',
      category: 'dependency_scanning',
      feedback_type: 'dismissal',
      branch: null,
      project_fingerprint: 'b3e9a7c4c9c3e642073802f47cb263b72d5fc7b3',
    },
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://hackerone.com/reports/310443',
      },
    ],
    location: {
      file: 'package.json',
      dependency: {
        package: {
          name: 'lodash',
        },
        version: '0.9.2',
      },
    },
    remediations: [null],
    solution: null,
    state: 'dismissed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/package.json',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Prototype pollution attack in lodash',
    severity: 'low',
    confidence: 'undefined',
    scanner: {
      external_id: 'retire.js',
      name: 'Retire.js',
    },
    identifiers: [
      {
        external_type: 'hackerone',
        external_id: '380873',
        name: 'HACKERONE-380873',
        url: 'https://hackerone.com/reports/380873',
      },
    ],
    project_fingerprint: '952e0bd07daeff4a6b9eb74489587d9a45d43618',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://hackerone.com/reports/380873',
      },
    ],
    location: {
      file: 'package.json',
      dependency: {
        package: {
          name: 'lodash',
        },
        version: '0.9.2',
      },
    },
    remediations: [null],
    solution: null,
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/package.json',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Possible XSS Vulnerability in Action View',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2016-6316',
        name: 'CVE-2016-6316',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-6316',
      },
    ],
    project_fingerprint: '59d6a9c3efe0e7f8546f54e9da52a18586a82ecc',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/I-VWr034ouk',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'actionview',
        },
        version: '5.0.0',
      },
    },
    remediations: [null],
    solution: 'upgrade to ~> 4.2.7.1, ~> 4.2.8, >= 5.0.0.1',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'File Content Disclosure in Action View',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-5418',
        name: 'CVE-2019-5418',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5418',
      },
    ],
    project_fingerprint: '2d08bc0d1a9d769a499ec894a004bc2a28aa51b5',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/pFRKI96Sm8Q',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'actionview',
        },
        version: '5.0.0',
      },
    },
    remediations: [null],
    solution:
      'upgrade to ~> 4.2.11, >= 4.2.11.1, ~> 5.0.7, >= 5.0.7.2, ~> 5.1.6, >= 5.1.6.2, ~> 5.2.2, >= 5.2.2.1, >= 6.0.0.beta3',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Denial of Service Vulnerability in Action View',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-5419',
        name: 'CVE-2019-5419',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5419',
      },
    ],
    project_fingerprint: '309613a96963d6a78a4a9a6becd0e12cbdcdf92c',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/GN7w9fFAQeI',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'actionview',
        },
        version: '5.0.0',
      },
    },
    remediations: [null],
    solution:
      'upgrade to >= 6.0.0.beta3, ~> 5.2.2, >= 5.2.2.1, ~> 5.1.6, >= 5.1.6.2, ~> 5.0.7, >= 5.0.7.2, ~> 4.2.11, >= 4.2.11.1',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Broken Access Control vulnerability in Active Job',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-16476',
        name: 'CVE-2018-16476',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-16476',
      },
    ],
    project_fingerprint: '00ab0a21cb6b9053f31a67ad2e38a0e217e86940',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/FL4dSdzr2zw',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'activejob',
        },
        version: '5.0.0',
      },
    },
    remediations: [null],
    solution: 'upgrade to ~> 4.2.11, ~> 5.0.7.1, ~> 5.1.6.1, ~> 5.1.7, >= 5.2.1.1',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Loofah XSS Vulnerability',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-16468',
        name: 'CVE-2018-16468',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-16468',
      },
    ],
    project_fingerprint: '2286a89c44459a79893d1938bbcb5b3bb36570d2',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/flavorjones/loofah/issues/154',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'loofah',
        },
        version: '2.2.0',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 2.2.3',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Loofah XSS Vulnerability',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-8048',
        name: 'CVE-2018-8048',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-8048',
      },
    ],
    project_fingerprint: '4106980cfa439be8b4872744f4f2b0d52369870f',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/flavorjones/loofah/issues/144',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'loofah',
        },
        version: '2.2.0',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 2.2.1',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Loofah XSS Vulnerability',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-15587',
        name: 'CVE-2019-15587',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15587',
      },
    ],
    project_fingerprint: '6bbe0b9cc8146e8ba3254f41aceab235b1205e24',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/flavorjones/loofah/issues/171',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'loofah',
        },
        version: '2.2.0',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 2.3.1',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Nokogiri gem, via libxml2, is affected by multiple vulnerabilities',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-14404',
        name: 'CVE-2018-14404',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-14404',
      },
    ],
    project_fingerprint: 'fdfd0fa067d7bb7640cfae1225c06d6385c12184',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/sparklemotion/nokogiri/issues/1785',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'nokogiri',
        },
        version: '1.8.2',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.8.5',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Revert libxml2 behavior in Nokogiri gem that could cause XSS',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-8048',
        name: 'CVE-2018-8048',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-8048',
      },
    ],
    project_fingerprint: '9b0932ddb23c550d45440b9b6e06a3b2a3308c12',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/sparklemotion/nokogiri/pull/1746',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'nokogiri',
        },
        version: '1.8.2',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.8.3',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Nokogiri gem, via libxslt, is affected by improper access control vulnerability',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-11068',
        name: 'CVE-2019-11068',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-11068',
      },
    ],
    project_fingerprint: '0d8a15926deff5803fbcf4c67097696d71980f80',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/sparklemotion/nokogiri/issues/1892',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'nokogiri',
        },
        version: '1.8.2',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.10.3',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Nokogiri gem, via libxslt, is affected by multiple vulnerabilities',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-13117',
        name: 'CVE-2019-13117',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-13117',
      },
    ],
    project_fingerprint: '91179c8d768cb5a8703684d0c7146aaecdf86a6e',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/sparklemotion/nokogiri/issues/1943',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'nokogiri',
        },
        version: '1.8.2',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.10.5',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Access of Resource Using Incompatible Type (Type Confusion) in nokogiri',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '66bbb585-09a1-4042-bb63-e57e64568ded',
        name: 'Gemnasium-66bbb585-09a1-4042-bb63-e57e64568ded',
        url: 'https://deps.sec.gitlab.com/packages/gem/nokogiri/versions/1.8.2/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-5815',
        name: 'CVE-2019-5815',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5815',
      },
    ],
    project_fingerprint: 'ef80df16b709ff861834058697da55962e364d9f',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'Type confusion in `xsltNumberFormatGetMultipleLevel` in libxslt, which is included in nokogiri, could allow attackers to potentially exploit heap corruption via crafted XML data.',
    links: [
      {
        url: 'https://bugs.chromium.org/p/chromium/issues/detail?id=930663',
      },
      {
        url:
          'https://gitlab.gnome.org/GNOME/libxslt/commit/08b62c25871b38d5d573515ca8a065b4b8f64f6b',
      },
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-5815',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'nokogiri',
        },
        version: '1.8.2',
      },
    },
    remediations: [null],
    solution: 'Upgrade to version 1.2.0 or above.',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Improper Input Validation in nokogiri',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: 'e81fe131-f92b-4449-bc54-ca2baa35b06f',
        name: 'Gemnasium-e81fe131-f92b-4449-bc54-ca2baa35b06f',
        url: 'https://deps.sec.gitlab.com/packages/gem/nokogiri/versions/1.8.2/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-13118',
        name: 'CVE-2019-13118',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-13118',
      },
    ],
    project_fingerprint: 'f8aad3eacb365dfccf4a19fd0fa96d1c74b8e509',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'In `numbers.c` in libxslt 1.1.33, which is used by nokogiri, a type holding grouping characters of an xsl:number instruction was too narrow and an invalid character/length combination could be passed to `xsltNumberFormatDecimal`, leading to a read of uninitialized stack data.',
    links: [
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-13118',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'nokogiri',
        },
        version: '1.8.2',
      },
    },
    remediations: [null],
    solution: 'Upgrade to version 1.10.5 or above.',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Use After Free in nokogiri',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: 'ecf64d0e-4f5c-4ebe-9f3f-c75ea81dc837',
        name: 'Gemnasium-ecf64d0e-4f5c-4ebe-9f3f-c75ea81dc837',
        url: 'https://deps.sec.gitlab.com/packages/gem/nokogiri/versions/1.8.2/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-18197',
        name: 'CVE-2019-18197',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18197',
      },
    ],
    project_fingerprint: '2736563bdd0d9075e7464bc5d7d6e1006b0a8b33',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      "In `xsltCopyText` in `transform.c` in libxslt, which is used by nokogiri, a pointer variable isn't reset under certain circumstances. If the relevant memory area happened to be freed and reused in a certain way, a bounds check could fail and memory outside a buffer could be written to, or uninitialized data could be disclosed.",
    links: [
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-18197',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'nokogiri',
        },
        version: '1.8.2',
      },
    },
    remediations: [null],
    solution: 'Upgrade to version 1.10.5 or above.',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Possible DoS vulnerability in Rack',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-16470',
        name: 'CVE-2018-16470',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-16470',
      },
    ],
    project_fingerprint: '3164e504d99881674f45ad55454da83ae7daf060',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/ruby-security-ann/Dz4sRl-ktKk',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rack',
        },
        version: '2.0.4',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 2.0.6',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Possible XSS vulnerability in Rack',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-16471',
        name: 'CVE-2018-16471',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-16471',
      },
    ],
    project_fingerprint: '4c6ead483b6618a0fcf72ec8733ddbf348957a73',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/ruby-security-ann/NAalCee8n6o',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rack',
        },
        version: '2.0.4',
      },
    },
    remediations: [null],
    solution: 'upgrade to ~> 1.6.11, >= 2.0.6',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Possible information leak / session hijack vulnerability',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-16782',
        name: 'CVE-2019-16782',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16782',
      },
    ],
    project_fingerprint: '3466df4927af559a87dc62927b1c081cfe06bdf5',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/rack/rack/security/advisories/GHSA-hrqr-hxpp-chr3',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rack',
        },
        version: '2.0.4',
      },
    },
    remediations: [null],
    solution: 'upgrade to ~> 1.6.12, >= 2.0.8',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'XSS vulnerability in rails-html-sanitizer',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-3741',
        name: 'CVE-2018-3741',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-3741',
      },
    ],
    project_fingerprint: '1655fe16f6de9d795f7e66ba81f74602145712da',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://groups.google.com/d/msg/rubyonrails-security/tP7W3kLc5u4/uDy2Br7xBgAJ',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rails-html-sanitizer',
        },
        version: '1.0.3',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.0.4',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Uncontrolled Resource Consumption in rails',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '03fb9fd8-0566-4b25-9a50-9918b3798ff4',
        name: 'Gemnasium-03fb9fd8-0566-4b25-9a50-9918b3798ff4',
        url: 'https://deps.sec.gitlab.com/packages/gem/rails/versions/5.0.0/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-5419',
        name: 'CVE-2019-5419',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5419',
      },
    ],
    project_fingerprint: 'ba87a8a599cc939a81d3da8700c742bcbf6b5624',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'There is a possible denial of service vulnerability in Action View (Rails) where specially crafted accept headers can cause action view to consume 100% cpu and make the server unresponsive.',
    links: [
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-5419',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rails',
        },
        version: '5.0.0',
      },
    },
    remediations: [null],
    solution: 'Upgrade to versions 4.2.11.1, 5.0.7.2, 5.1.6.2, 5.2.2.1 or above.',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Deserialization of Untrusted Data in rails',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '18b3b503-c508-4713-9bb9-057fcefe6dfe',
        name: 'Gemnasium-18b3b503-c508-4713-9bb9-057fcefe6dfe',
        url: 'https://deps.sec.gitlab.com/packages/gem/rails/versions/5.0.0/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2018-16476',
        name: 'CVE-2018-16476',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-16476',
      },
    ],
    project_fingerprint: '7d7f5c8007b8ef709e0665ff51da2ceb0231003f',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'A Broken Access Control vulnerability in Active Job allows an attacker to craft user input which can cause Active Job to deserialize it using GlobalId and give them access to information that they should not have.',
    links: [
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2018-16476',
      },
      {
        url: 'https://weblog.rubyonrails.org/2018/11/27/Rails-4-2-5-0-5-1-5-2-have-been-released/',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rails',
        },
        version: '5.0.0',
      },
    },
    remediations: [null],
    solution: 'Upgrade to versions 4.2.11, 5.0.7.1, 5.1.6.1, 5.2.1.1 or above.',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Improper Input Validation in rails',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '31ddd20a-862e-4bb9-a953-de04bb4c7caf',
        name: 'Gemnasium-31ddd20a-862e-4bb9-a953-de04bb4c7caf',
        url: 'https://deps.sec.gitlab.com/packages/gem/rails/versions/5.0.0/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-5420',
        name: 'CVE-2019-5420',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5420',
      },
    ],
    project_fingerprint: '493d30d2220fc3c3f1522814de8a33c4d3a37e17',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'A remote code execution vulnerability in development mode Rails can allow an attacker to guess the automatically generated development mode secret token. This secret token can be used in combination with other Rails internals to escalate to a remote code execution exploit.',
    links: [
      {
        url:
          'http://packetstormsecurity.com/files/152704/Ruby-On-Rails-DoubleTap-Development-Mode-secret_key_base-Remote-Code-Execution.html',
      },
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-5420',
      },
      {
        url: 'https://weblog.rubyonrails.org/2019/3/13/Rails-4-2-5-1-5-1-6-2-have-been-released/',
      },
      {
        url: 'https://www.exploit-db.com/exploits/46785/',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rails',
        },
        version: '5.0.0',
      },
    },
    remediations: [null],
    solution: 'Upgrade to versions 5.2.2.1, 6.0.0 or above.',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Information Exposure in rails',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '8d1df401-d117-44ce-8106-c147d960ae4c',
        name: 'Gemnasium-8d1df401-d117-44ce-8106-c147d960ae4c',
        url: 'https://deps.sec.gitlab.com/packages/gem/rails/versions/5.0.0/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-5418',
        name: 'CVE-2019-5418',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5418',
      },
    ],
    project_fingerprint: 'ad38fa2b94c8811c82f922688cf3136c2f8f2bb8',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      "There is a File Content Disclosure vulnerability in Action View where specially crafted accept headers can cause contents of arbitrary files on the target system's filesystem to be exposed.",
    links: [
      {
        url:
          'http://packetstormsecurity.com/files/152178/Rails-5.2.1-Arbitrary-File-Content-Disclosure.html',
      },
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-5418',
      },
      {
        url: 'https://weblog.rubyonrails.org/2019/3/13/Rails-4-2-5-1-5-1-6-2-have-been-released/',
      },
      {
        url: 'https://www.exploit-db.com/exploits/46585/',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rails',
        },
        version: '5.0.0',
      },
    },
    remediations: [null],
    solution: 'Upgrade to versions 4.2.11.1, 5.0.7.2, 5.1.6.2, 5.2.2.1 or above.',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Directory Traversal in rubyzip',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-1000544',
        name: 'CVE-2018-1000544',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-1000544',
      },
    ],
    project_fingerprint: 'b580a421ddf1529e6da5834c6d0cd720c2f4938f',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/rubyzip/rubyzip/issues/369',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rubyzip',
        },
        version: '1.2.1',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.2.2',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Denial of Service in rubyzip ("zip bombs")',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-16892',
        name: 'CVE-2019-16892',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16892',
      },
    ],
    project_fingerprint: '74704b563f545fb1b99603828adb9c05eabe5a5f',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://github.com/rubyzip/rubyzip/pull/403',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'rubyzip',
        },
        version: '1.2.1',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 1.3.0',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Path Traversal in Sprockets',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'bundler_audit',
      name: 'bundler-audit',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-3760',
        name: 'CVE-2018-3760',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-3760',
      },
    ],
    project_fingerprint: '6a68f5dd9cd053a62d3f2ffc89854ada1d6fb009',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      {
        url: 'https://groups.google.com/forum/#!topic/ruby-security-ann/2S9Pwz2i16k',
      },
    ],
    location: {
      file: 'Gemfile.lock',
      dependency: {
        package: {
          name: 'sprockets',
        },
        version: '3.7.1',
      },
    },
    remediations: [null],
    solution: 'upgrade to >= 2.12.5, < 3.0.0, >= 3.7.2, < 4.0.0, >= 4.0.0.beta8',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/Gemfile.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'No Charset in Content-Type Header in express',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: 'd5cb7112-f79e-4496-8417-7d42047f108a',
        name: 'Gemnasium-d5cb7112-f79e-4496-8417-7d42047f108a',
        url: 'https://deps.sec.gitlab.com/packages/npm/express/versions/1.0.0/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2014-6393',
        name: 'CVE-2014-6393',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-6393',
      },
    ],
    project_fingerprint: '864e14311d9d3ff2367f591d3bc2fb26c921aa69',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      "Express do not specify a charset field in the content-type header while displaying 400 level response messages. The lack of enforcing user's browser to set correct charset, could be leveraged by an attacker to perform a cross-site scripting attack, using non-standard encodings, like UTF-7.",
    links: [
      {
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-6393',
      },
      {
        url: 'https://nodesecurity.io/advisories/8',
      },
    ],
    location: {
      file: 'yarn.lock',
      dependency: {
        package: {
          name: 'express',
        },
        version: '1.0.0',
      },
    },
    remediations: [null],
    solution: 'Upgrade to latest version.',
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/yarn.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Uncontrolled Resource Consumption in lodash',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '109f3b4c-bdb3-48be-b2f9-e0348fba64bd',
        name: 'Gemnasium-109f3b4c-bdb3-48be-b2f9-e0348fba64bd',
        url: 'https://deps.sec.gitlab.com/packages/npm/lodash/versions/2.4.2/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-1010266',
        name: 'CVE-2019-1010266',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-1010266',
      },
    ],
    project_fingerprint: 'c1959bd964d805dfc52755409195f947358971e3',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'lodash is affected by Uncontrolled Resource Consumption which can lead to a denial of service.',
    links: [
      {
        url: 'https://github.com/lodash/lodash/issues/3359',
      },
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-1010266',
      },
    ],
    location: {
      file: 'yarn.lock',
      dependency: {
        package: {
          name: 'lodash',
        },
        version: '2.4.2',
      },
    },
    remediations: [null],
    solution: 'Upgrade to version 4.17.11 or above.',
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/yarn.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Denial of Service and remote code execution in lodash',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '46774bb9-9ce5-4ffe-9bc8-4e610d24df43',
        name: 'Gemnasium-46774bb9-9ce5-4ffe-9bc8-4e610d24df43',
        url: 'https://deps.sec.gitlab.com/packages/npm/lodash/versions/2.4.2/advisories',
      },
    ],
    project_fingerprint: 'fb2e9ef93efdf290a2fbe1140f25d25e1204cd38',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'Functions in Lodash ( merge, mergeWith, defaultsDeep) can modify the prototype of "Object" if given malicious data. This can lead to denial of service or remote code execution.',
    links: [
      {
        url: 'https://github.com/lodash/lodash/commit/d8e069cc3410082e44eb18fcf8e7f3d08ebe1d4a',
      },
      {
        url: 'https://hackerone.com/reports/310443',
      },
    ],
    location: {
      file: 'yarn.lock',
      dependency: {
        package: {
          name: 'lodash',
        },
        version: '2.4.2',
      },
    },
    remediations: [null],
    solution: 'Upgrade to latest version.',
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/yarn.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Improper Input Validation in lodash',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '4774cd67-936f-419e-8533-ae5cfe7db9f9',
        name: 'Gemnasium-4774cd67-936f-419e-8533-ae5cfe7db9f9',
        url: 'https://deps.sec.gitlab.com/packages/npm/lodash/versions/0.9.2/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-10744',
        name: 'CVE-2019-10744',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-10744',
      },
    ],
    project_fingerprint: '44557ea6a12364c17181d08f7232800fccd0f25f',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'lodash is vulnerable to Prototype Pollution. The function `defaultsDeep` could be tricked into adding or modifying properties of `Object.prototype` using a constructor payload.',
    links: [
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-10744',
      },
    ],
    location: {
      file: 'yarn.lock',
      dependency: {
        package: {
          name: 'lodash',
        },
        version: '0.9.2',
      },
    },
    remediations: [null],
    solution: 'Upgrade to version 4.17.12 or above.',
    state: 'confirmed',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/yarn.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Modification of Assumed-Immutable Data (MAID) in lodash',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: 'd85c7e84-cd50-4829-85a4-7e0e69f1b396',
        name: 'Gemnasium-d85c7e84-cd50-4829-85a4-7e0e69f1b396',
        url: 'https://deps.sec.gitlab.com/packages/npm/lodash/versions/0.9.2/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2018-3721',
        name: 'CVE-2018-3721',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-3721',
      },
    ],
    project_fingerprint: '97eff9b043f2f336db004fcd8d23dfaa0675778c',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'lodash node module suffers from a Modification of Assumed-Immutable Data (MAID) vulnerability via defaultsDeep, merge, and mergeWith functions, which allows a malicious user to modify the prototype of `Object` via `__proto__`, causing the addition or modification of an existing property that will exist on all objects.',
    links: [
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2018-3721',
      },
    ],
    location: {
      file: 'yarn.lock',
      dependency: {
        package: {
          name: 'lodash',
        },
        version: '0.9.2',
      },
    },
    remediations: [null],
    solution: 'Upgrade to version 4.17.5 or above.',
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/yarn.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Uncontrolled Resource Consumption in lodash',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: 'd8822263-8a6f-43ea-bb6b-7a2a0cabdf5c',
        name: 'Gemnasium-d8822263-8a6f-43ea-bb6b-7a2a0cabdf5c',
        url: 'https://deps.sec.gitlab.com/packages/npm/lodash/versions/2.4.2/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2018-16487',
        name: 'CVE-2018-16487',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-16487',
      },
    ],
    project_fingerprint: 'f03e504757381bf4025bdc109373d24b712a79a1',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'A prototype pollution vulnerability was found in lodash where the functions `merge`, `mergeWith`, and `defaultsDeep` can be tricked into adding or modifying properties of `Object.prototype`.',
    links: [
      {
        url: 'https://hackerone.com/reports/380873',
      },
      {
        url: 'https://nvd.nist.gov/vuln/detail/CVE-2018-16487',
      },
    ],
    location: {
      file: 'yarn.lock',
      dependency: {
        package: {
          name: 'lodash',
        },
        version: '2.4.2',
      },
    },
    remediations: [null],
    solution: 'Upgrade to version 4.17.11 or above.',
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/yarn.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Regular Expression Denial of Service in minimatch',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '7d9ba955-fd99-4503-936e-f6833768f76e',
        name: 'Gemnasium-7d9ba955-fd99-4503-936e-f6833768f76e',
        url: 'https://deps.sec.gitlab.com/packages/npm/minimatch/versions/0.3.0/advisories',
      },
    ],
    project_fingerprint: '1821acbb48da422f00aaf9e1ad8452c46e48bdc6',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'The primary function, `minimatch(path, pattern)` is vulnerable to ReDoS in the `pattern` parameter.  This is because of the regular expression on line 521 of minimatch.js: `/((?:\\\\{2})*)(\\\\?)\\|/g,`.  The problematic portion of the regex is `((?:\\\\{2})*)` which matches against `//`.',
    links: [
      {
        url: 'https://nodesecurity.io/advisories/118',
      },
    ],
    location: {
      file: 'yarn.lock',
      dependency: {
        package: {
          name: 'minimatch',
        },
        version: '0.3.0',
      },
    },
    remediations: [null],
    solution: 'Upgrade to latest version.',
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/yarn.lock',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js',
    severity: 'unknown',
    confidence: 'undefined',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '9952e574-7b5b-46fa-a270-aeb694198a98',
        name: 'Gemnasium-9952e574-7b5b-46fa-a270-aeb694198a98',
        url: 'https://deps.sec.gitlab.com/packages/npm/saml2-js/versions/2.0.0/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2017-11429',
        name: 'CVE-2017-11429',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-11429',
      },
    ],
    project_fingerprint: 'fa6f5b6c5d240b834ac5e901dc69f9484cef89ec',
    create_vulnerability_feedback_issue_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/secure-team-test/dependency-list-test/-/vulnerability_feedback',
    project: {
      id: 4392789,
      name: 'dependency-list-test',
      full_path: '/secure-team-test/dependency-list-test',
      full_name: 'secure-team-test / dependency-list-test',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'Some XML DOM traversal and canonicalization APIs may be inconsistent in handling of comments within XML nodes. Incorrect use of these APIs by some SAML libraries results in incorrect parsing of the inner text of XML nodes such that any inner text after the comment is lost prior to cryptographically signing the SAML message. Text after the comment therefore has no impact on the signature on the SAML message.\r\n\r\nA remote attacker can modify SAML content for a SAML service provider without invalidating the cryptographic signature, which may allow attackers to bypass primary authentication for the affected SAML service provider.',
    links: [
      {
        url:
          'https://github.com/Clever/saml2/commit/3546cb61fd541f219abda364c5b919633609ef3d#diff-af730f9f738de1c9ad87596df3f6de84R279',
      },
      {
        url: 'https://github.com/Clever/saml2/issues/127',
      },
      {
        url: 'https://www.kb.cert.org/vuls/id/475445',
      },
    ],
    location: {
      file: 'yarn.lock',
      dependency: {
        package: {
          name: 'saml2-js',
        },
        version: '2.0.0',
      },
    },
    remediations: [null],
    solution: 'Upgrade to fixed version.\r\n',
    state: 'detected',
    blob_path:
      '/secure-team-test/dependency-list-test/-/blob/4f893b5307903bb02fad9b432891392e03af65fd/yarn.lock',
  },

  // From
  // https://gitlab.com/gitlab-examples/security/simply-simple-notes/-/security/dashboard/?project_id=15310444&scope=dismissed&page=1&days=90
  {
    id: 1083224,
    report_type: 'dast',
    name: 'X-Frame-Options Header Not Set',
    severity: 'medium',
    confidence: 'medium',
    scanner: {
      external_id: 'zaproxy',
      name: 'ZAProxy',
    },
    identifiers: [
      {
        external_type: 'ZAProxy_PluginId',
        external_id: '10020',
        name: 'X-Frame-Options Header Not Set',
        url: 'https://github.com/zaproxy/zaproxy/blob/w2019-01-14/docs/scanners.md',
      },
      {
        external_type: 'CWE',
        external_id: '16',
        name: 'CWE-16',
        url: 'https://cwe.mitre.org/data/definitions/16.html',
      },
      {
        external_type: 'WASC',
        external_id: '15',
        name: 'WASC-15',
        url:
          'http://projects.webappsec.org/w/page/13246974/Threat%20Classification%20Reference%20Grid',
      },
    ],
    project_fingerprint: '12267388ce4e4ab1accaf21c02deb352a7185b58',
    create_vulnerability_feedback_issue_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    project: {
      id: 15310444,
      name: 'simply-simple-notes',
      full_path: '/gitlab-examples/security/simply-simple-notes',
      full_name: 'GitLab-examples / security / simply-simple-notes',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      "X-Frame-Options header is not included in the HTTP response to protect against 'ClickJacking' attacks.",
    links: [
      {
        url:
          'http://blogs.msdn.com/b/ieinternals/archive/2010/03/30/combating-clickjacking-with-x-frame-options.aspx',
      },
    ],
    location: {
      param: 'X-Frame-Options',
      method: 'GET',
      hostname: 'https://35.193.92.65',
      path: '/',
    },
    remediations: null,
    solution:
      "Most modern Web browsers support the X-Frame-Options HTTP header. Ensure it's set on all web pages returned by your site (if you expect the page to be framed only by pages on your server (e.g. it's part of a FRAMESET) then you'll want to use SAMEORIGIN, otherwise if you never expect the page to be framed, you should use DENY. ALLOW-FROM allows specific websites to frame the web page in supported web browsers).",
    state: 'detected',
    blob_path: '',
  },
  {
    id: 1083225,
    report_type: 'dast',
    name: 'Incomplete or No Cache-control and Pragma HTTP Header Set',
    severity: 'low',
    confidence: 'medium',
    scanner: {
      external_id: 'zaproxy',
      name: 'ZAProxy',
    },
    identifiers: [
      {
        external_type: 'ZAProxy_PluginId',
        external_id: '10015',
        name: 'Incomplete or No Cache-control and Pragma HTTP Header Set',
        url: 'https://github.com/zaproxy/zaproxy/blob/w2019-01-14/docs/scanners.md',
      },
      {
        external_type: 'CWE',
        external_id: '525',
        name: 'CWE-525',
        url: 'https://cwe.mitre.org/data/definitions/525.html',
      },
      {
        external_type: 'WASC',
        external_id: '13',
        name: 'WASC-13',
        url:
          'http://projects.webappsec.org/w/page/13246974/Threat%20Classification%20Reference%20Grid',
      },
    ],
    project_fingerprint: '848f94fe8447cfc4e8a68d434a9f794323b3f095',
    create_vulnerability_feedback_issue_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    project: {
      id: 15310444,
      name: 'simply-simple-notes',
      full_path: '/gitlab-examples/security/simply-simple-notes',
      full_name: 'GitLab-examples / security / simply-simple-notes',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'The cache-control and pragma HTTP header have not been set properly or are missing allowing the browser and proxies to cache content.',
    links: [
      {
        url: 'https://www.owasp.org/index.php/Session_Management_Cheat_Sheet#Web_Content_Caching',
      },
    ],
    location: {
      param: 'Cache-Control',
      method: 'GET',
      hostname: 'https://35.193.92.65',
      path: '/',
    },
    remediations: null,
    solution:
      'Whenever possible ensure the cache-control HTTP header is set with no-cache, no-store, must-revalidate; and that the pragma HTTP header is set with no-cache.',
    state: 'detected',
    blob_path: '',
  },
  {
    id: 1083226,
    report_type: 'dast',
    name: 'Web Browser XSS Protection Not Enabled',
    severity: 'low',
    confidence: 'medium',
    scanner: {
      external_id: 'zaproxy',
      name: 'ZAProxy',
    },
    identifiers: [
      {
        external_type: 'ZAProxy_PluginId',
        external_id: '10016',
        name: 'Web Browser XSS Protection Not Enabled',
        url: 'https://github.com/zaproxy/zaproxy/blob/w2019-01-14/docs/scanners.md',
      },
      {
        external_type: 'CWE',
        external_id: '933',
        name: 'CWE-933',
        url: 'https://cwe.mitre.org/data/definitions/933.html',
      },
      {
        external_type: 'WASC',
        external_id: '14',
        name: 'WASC-14',
        url:
          'http://projects.webappsec.org/w/page/13246974/Threat%20Classification%20Reference%20Grid',
      },
    ],
    project_fingerprint: 'd5483a1cc23a663f7f40a83264396397a9bee8ab',
    create_vulnerability_feedback_issue_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    project: {
      id: 15310444,
      name: 'simply-simple-notes',
      full_path: '/gitlab-examples/security/simply-simple-notes',
      full_name: 'GitLab-examples / security / simply-simple-notes',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      "Web Browser XSS Protection is not enabled, or is disabled by the configuration of the 'X-XSS-Protection' HTTP response header on the web server",
    links: [
      {
        url: 'https://www.owasp.org/index.php/XSS_(Cross_Site_Scripting)_Prevention_Cheat_Sheet',
      },
      {
        url: 'https://www.veracode.com/blog/2014/03/guidelines-for-setting-security-headers/',
      },
    ],
    location: {
      param: 'X-XSS-Protection',
      method: 'GET',
      hostname: 'https://35.193.92.65',
      path: '/',
    },
    remediations: null,
    solution:
      "Ensure that the web browser's XSS filter is enabled, by setting the X-XSS-Protection HTTP response header to '1'.",
    state: 'detected',
    blob_path: '',
  },
  {
    id: 1083227,
    report_type: 'dast',
    name: 'X-Content-Type-Options Header Missing',
    severity: 'low',
    confidence: 'medium',
    scanner: {
      external_id: 'zaproxy',
      name: 'ZAProxy',
    },
    identifiers: [
      {
        external_type: 'CWE',
        external_id: '16',
        name: 'CWE-16',
        url: 'https://cwe.mitre.org/data/definitions/16.html',
      },
      {
        external_type: 'WASC',
        external_id: '15',
        name: 'WASC-15',
        url:
          'http://projects.webappsec.org/w/page/13246974/Threat%20Classification%20Reference%20Grid',
      },
      {
        external_type: 'ZAProxy_PluginId',
        external_id: '10021',
        name: 'X-Content-Type-Options Header Missing',
        url: 'https://github.com/zaproxy/zaproxy/blob/w2019-01-14/docs/scanners.md',
      },
    ],
    project_fingerprint: 'a9b4daaa58292bac4bad5c1c3cf56398f25112f8',
    create_vulnerability_feedback_issue_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    project: {
      id: 15310444,
      name: 'simply-simple-notes',
      full_path: '/gitlab-examples/security/simply-simple-notes',
      full_name: 'GitLab-examples / security / simply-simple-notes',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      "The Anti-MIME-Sniffing header X-Content-Type-Options was not set to 'nosniff'. This allows older versions of Internet Explorer and Chrome to perform MIME-sniffing on the response body, potentially causing the response body to be interpreted and displayed as a content type other than the declared content type. Current (early 2014) and legacy versions of Firefox will use the declared content type (if one is set), rather than performing MIME-sniffing.",
    links: [
      {
        url: 'http://msdn.microsoft.com/en-us/library/ie/gg622941%28v=vs.85%29.aspx',
      },
      {
        url: 'https://www.owasp.org/index.php/List_of_useful_HTTP_headers',
      },
    ],
    location: {
      param: 'X-Content-Type-Options',
      method: 'GET',
      hostname: 'https://35.193.92.65',
      path: '/',
    },
    remediations: null,
    solution:
      "Ensure that the application/web server sets the Content-Type header appropriately, and that it sets the X-Content-Type-Options header to 'nosniff' for all web pages.If possible, ensure that the end user uses a standards-compliant and modern web browser that does not perform MIME-sniffing at all, or that can be directed by the web application/web server to not perform MIME-sniffing.",
    state: 'detected',
    blob_path: '',
  },
  {
    id: 1083233,
    report_type: 'container_scanning',
    name: 'CVE-2018-20843 in expat',
    severity: 'unknown',
    confidence: 'unknown',
    scanner: {
      external_id: 'clair',
      name: 'Clair',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-20843',
        name: 'CVE-2018-20843',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-20843',
      },
    ],
    project_fingerprint: '7cd325b2569af43679faa1a9053cce14242bd1ff',
    create_vulnerability_feedback_issue_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    project: {
      id: 15310444,
      name: 'simply-simple-notes',
      full_path: '/gitlab-examples/security/simply-simple-notes',
      full_name: 'GitLab-examples / security / simply-simple-notes',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: 'expat:2.2.5-r0 is affected by CVE-2018-20843',
    links: [
      {
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-20843',
      },
    ],
    location: {
      image:
        'registry.gitlab.com/gitlab-examples/security/simply-simple-notes/master:1c0696712993e70a68dda9e3d5bba5fe38432f97',
      operating_system: 'alpine:v3.7',
      dependency: {
        package: {
          name: 'expat',
        },
        version: '2.2.5-r0',
      },
    },
    remediations: null,
    solution: 'Upgrade expat from 2.2.5-r0 to 2.2.7-r0',
    state: 'detected',
    blob_path: '',
  },
  {
    id: 1083234,
    report_type: 'container_scanning',
    name: 'CVE-2019-14697 in musl',
    severity: 'unknown',
    confidence: 'unknown',
    scanner: {
      external_id: 'clair',
      name: 'Clair',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-14697',
        name: 'CVE-2019-14697',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-14697',
      },
    ],
    project_fingerprint: '42bf25f6f1ae68d50326c73f61cff192b73cc62e',
    create_vulnerability_feedback_issue_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    project: {
      id: 15310444,
      name: 'simply-simple-notes',
      full_path: '/gitlab-examples/security/simply-simple-notes',
      full_name: 'GitLab-examples / security / simply-simple-notes',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: 'musl:1.1.18-r3 is affected by CVE-2019-14697',
    links: [
      {
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-14697',
      },
    ],
    location: {
      image:
        'registry.gitlab.com/gitlab-examples/security/simply-simple-notes/master:1c0696712993e70a68dda9e3d5bba5fe38432f97',
      operating_system: 'alpine:v3.7',
      dependency: {
        package: {
          name: 'musl',
        },
        version: '1.1.18-r3',
      },
    },
    remediations: null,
    solution: 'Upgrade musl from 1.1.18-r3 to 1.1.18-r4',
    state: 'detected',
    blob_path: '',
  },
  {
    id: 1083235,
    report_type: 'container_scanning',
    name: 'CVE-2019-15903 in expat',
    severity: 'unknown',
    confidence: 'unknown',
    scanner: {
      external_id: 'clair',
      name: 'Clair',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-15903',
        name: 'CVE-2019-15903',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15903',
      },
    ],
    project_fingerprint: '7aa76f5895f1c668e3bf448170744749f2f791b4',
    create_vulnerability_feedback_issue_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path:
      '/gitlab-examples/security/simply-simple-notes/-/vulnerability_feedback',
    project: {
      id: 15310444,
      name: 'simply-simple-notes',
      full_path: '/gitlab-examples/security/simply-simple-notes',
      full_name: 'GitLab-examples / security / simply-simple-notes',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description: 'expat:2.2.5-r0 is affected by CVE-2019-15903',
    links: [
      {
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15903',
      },
    ],
    location: {
      image:
        'registry.gitlab.com/gitlab-examples/security/simply-simple-notes/master:1c0696712993e70a68dda9e3d5bba5fe38432f97',
      operating_system: 'alpine:v3.7',
      dependency: {
        package: {
          name: 'expat',
        },
        version: '2.2.5-r0',
      },
    },
    remediations: null,
    solution: 'Upgrade expat from 2.2.5-r0 to 2.2.7-r1',
    state: 'detected',
    blob_path: '',
  },
];
