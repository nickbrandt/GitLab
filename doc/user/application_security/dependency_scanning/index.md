# Dependency Scanning **[ULTIMATE]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/5105)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.7.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can analyze your dependencies for known
vulnerabilities using Dependency Scanning.

You can take advantage of Dependency Scanning by either [including the CI job](#including-the-provided-template)
in your existing `.gitlab-ci.yml` file or by implicitly using
[Auto Dependency Scanning](../../../topics/autodevops/index.md#auto-dependency-scanning-ultimate)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab checks the Dependency Scanning report, compares the found vulnerabilities
between the source and target branches, and shows the information right on the
merge request.

![Dependency Scanning Widget](img/dependency_scanning.png)

The results are sorted by the severity of the vulnerability:

1. Critical
1. High
1. Medium
1. Low
1. Unknown
1. Everything else

## Use cases

It helps to automatically find security vulnerabilities in your dependencies
while you are developing and testing your applications. For example when your
application is using an external (open source) library which is known to be vulnerable.

## Requirements

To run a Dependency Scanning job, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html#running-privileged-containers-for-the-runners)
executor running in privileged mode. If you're using the shared Runners on GitLab.com,
this is enabled by default.

## Supported languages and package managers

The following languages and dependency managers are supported.

| Language (package managers)                                                 | Scan tool                                                                                                                         |
|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| JavaScript ([npm](https://www.npmjs.com/), [yarn](https://yarnpkg.com/en/)) | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general), [Retire.js](https://retirejs.github.io/retire.js)         |
| Python ([pip](https://pip.pypa.io/en/stable/)) (only `requirements.txt` supported)  | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general)                                                            |
| Ruby ([gem](https://rubygems.org/))                                         | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general), [bundler-audit](https://github.com/rubysec/bundler-audit) |
| Java ([Maven](https://maven.apache.org/))                                   | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general)                                                            |
| PHP ([Composer](https://getcomposer.org/))                                  | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general)                                                            |

Some scanners require to send a list of project dependencies to GitLab's central
servers to check for vulnerabilities. To learn more about this or to disable it,
refer to the [GitLab Dependency Scanning tool documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#remote-checks).

## Configuring Dependency Scanning

To enable Dependency Scanning in your project, define a job in your `.gitlab-ci.yml`
file that generates the
[Dependency Scanning report artifact](../../../ci/yaml/README.md#artifactsreportsdependency_scanning-ultimate).

This can be done in two ways:

- For GitLab 11.9 and later, including the provided Dependency Scanning
  `.gitlab-ci.yml` template (recommended).
- Manually specifying the job definition. Not recommended unless using GitLab
  11.8 and earlier.

### Including the provided template

NOTE: **Note:**
The CI/CD Dependency Scanning template is supported on GitLab 11.9 and later versions.
For earlier versions, use the [manual job definition](#manual-job-definition-for-gitlab-115-and-later).

A CI/CD [Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
with the default Dependency Scanning job definition is provided as a part of your GitLab
installation which you can [include](../../../ci/yaml/README.md#includetemplate)
in your `.gitlab-ci.yml` file.

To enable Dependency Scanning using the provided template, add the following to
your `.gitlab-ci.yml` file:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml
```

The included template will create a `dependency_scanning` job in your CI/CD
pipeline and scan your project's source code for possible vulnerabilities.

The report will be saved as a
[Dependency Scanning report artifact](../../../ci/yaml/README.md#artifactsreportsdependency_scanning-ultimate)
that you can later download and analyze. Due to implementation limitations, we
always take the latest Dependency Scanning artifact available.

Some security scanners require to send a list of project dependencies to GitLab
central servers to check for vulnerabilities. To learn more about this or to
disable it, check the
[GitLab Dependency Scanning tool documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#remote-checks).

#### Customizing the Dependency Scanning settings

The Dependency Scanning settings can be changed through environment variables by using the
[`variables`](../../../ci/yaml/README.md#variables) parameter in `.gitlab-ci.yml`.
These variables are documented in the
[Dependency Scanning tool documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#settings).

For example:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

variables:
  DEP_SCAN_DISABLE_REMOTE_CHECKS: true
```

Because template is [evaluated before](../../../ci/yaml/README.md#include) the pipeline
configuration, the last mention of the variable will take precedence.

#### Overriding the Dependency Scanning template

If you want to override the job definition (for example, change properties like
`variables` or `dependencies`), you need to declare a `dependency_scanning` job
after the template inclusion and specify any additional keys under it. For example:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

dependency_scanning:
  variables:
    CI_DEBUG_TRACE: "true"
```

### Manual job definition for GitLab 11.5 and later

For GitLab 11.5 and GitLab Runner 11.5 and later, the following `dependency_scanning`
job can be added:

```yaml
dependency_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export DS_VERSION=${SP_VERSION:-$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')}
    - |
      docker run \
      --env DS_ANALYZER_IMAGES \
      --env DS_ANALYZER_IMAGE_PREFIX \
      --env DS_ANALYZER_IMAGE_TAG \
      --env DS_DEFAULT_ANALYZERS \
      --env DEP_SCAN_DISABLE_REMOTE_CHECKS \
      --env DS_DOCKER_CLIENT_NEGOTIATION_TIMEOUT \
      --env DS_PULL_ANALYZER_IMAGE_TIMEOUT \
      --env DS_RUN_ANALYZER_TIMEOUT \
      --volume "$PWD:/code" \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$DS_VERSION" /code
  dependencies: []
  artifacts:
    reports:
      dependency_scanning: gl-dependency-scanning-report.json
```

You can supply many other [settings variables](https://gitlab.com/gitlab-org/security-products/dependency-scanning#settings)
via `docker run --env` to customize your job execution.

### Manual job definition for GitLab 11.4 and earlier (deprecated)

CAUTION: **Caution:**
Before GitLab 11.5, the Dependency Scanning job and artifact had to be named specifically
to automatically extract the report data and show it in the merge request widget.
While these old job definitions are still maintained, they have been deprecated
and may be removed in the next major release, GitLab 12.0. You are strongly advised
to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the job should look like:

```yaml
dependency_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export DS_VERSION=${SP_VERSION:-$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')}
    - |
      docker run \
      --env DS_ANALYZER_IMAGES \
      --env DS_ANALYZER_IMAGE_PREFIX \
      --env DS_ANALYZER_IMAGE_TAG \
      --env DS_DEFAULT_ANALYZERS \
      --env DS_EXCLUDED_PATHS \
      --env DEP_SCAN_DISABLE_REMOTE_CHECKS \
      --env DS_DOCKER_CLIENT_NEGOTIATION_TIMEOUT \
      --env DS_PULL_ANALYZER_IMAGE_TIMEOUT \
      --env DS_RUN_ANALYZER_TIMEOUT \
      --volume "$PWD:/code" \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$DS_VERSION" /code
  artifacts:
    paths: [gl-dependency-scanning-report.json]
```

## Reports JSON format

CAUTION: **Caution:**
JSON report artifacts are not a public API of Dependency Scanning and their format may change in future.

Dependency Scanning tool emits a JSON report report file. Here is an example of a structure for such report will all important parts of
it highlighted:

```json5
{
  "version": "2.0",
  "vulnerabilities": [
    {
      "category": "dependency_scanning",
      "name": "Regular Expression Denial of Service",
      "message": "Regular Expression Denial of Service in debug",
      "description": "The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.",
      "cve": "yarn.lock:debug:gemnasium:37283ed4-0380-40d7-ada7-2d994afcc62a",
      "severity": "Unknown",
      "solution": "Upgrade to latest versions.",
      "scanner": {
        "id": "gemnasium",
        "name": "Gemnasium"
      },
      "location": {
        "file": "yarn.lock",
        "dependency": {
          "package": {
            "name": "debug"
          },
          "version": "1.0.5"
        }
      },
      "identifiers": [
        {
          "type": "gemnasium",
          "name": "Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a",
          "value": "37283ed4-0380-40d7-ada7-2d994afcc62a",
          "url": "https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories"
        }
      ],
      "links": [
        {
          "url": "https://nodesecurity.io/advisories/534"
        },
        {
          "url": "https://github.com/visionmedia/debug/issues/501"
        },
        {
          "url": "https://github.com/visionmedia/debug/pull/504"
        }
      ]
    },
    {
      "category": "dependency_scanning",
      "name": "Authentication bypass via incorrect DOM traversal and canonicalization",
      "message": "Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js",
      "description": "Some XML DOM traversal and canonicalization APIs may be inconsistent in handling of comments within XML nodes. Incorrect use of these APIs by some SAML libraries results in incorrect parsing of the inner text of XML nodes such that any inner text after the comment is lost prior to cryptographically signing the SAML message. Text after the comment therefore has no impact on the signature on the SAML message.\r\n\r\nA remote attacker can modify SAML content for a SAML service provider without invalidating the cryptographic signature, which may allow attackers to bypass primary authentication for the affected SAML service provider.",
      "cve": "yarn.lock:saml2-js:gemnasium:9952e574-7b5b-46fa-a270-aeb694198a98",
      "severity": "Unknown",
      "solution": "Upgrade to fixed version.\r\n",
      "scanner": {
        "id": "gemnasium",
        "name": "Gemnasium"
      },
      "location": {
        "file": "yarn.lock",
        "dependency": {
          "package": {
            "name": "saml2-js"
          },
          "version": "1.5.0"
        }
      },
      "identifiers": [
        {
          "type": "gemnasium",
          "name": "Gemnasium-9952e574-7b5b-46fa-a270-aeb694198a98",
          "value": "9952e574-7b5b-46fa-a270-aeb694198a98",
          "url": "https://deps.sec.gitlab.com/packages/npm/saml2-js/versions/1.5.0/advisories"
        },
        {
          "type": "cve",
          "name": "CVE-2017-11429",
          "value": "CVE-2017-11429",
          "url": "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-11429"
        }
      ],
      "links": [
        {
          "url": "https://github.com/Clever/saml2/commit/3546cb61fd541f219abda364c5b919633609ef3d#diff-af730f9f738de1c9ad87596df3f6de84R279"
        },
        {
          "url": "https://github.com/Clever/saml2/issues/127"
        },
        {
          "url": "https://www.kb.cert.org/vuls/id/475445"
        }
      ]
    }
  ],
  "remediations": [
    {
      "fixes": [
        {
          "cve": "yarn.lock:saml2-js:gemnasium:9952e574-7b5b-46fa-a270-aeb694198a98"
        }
      ],
      "summary": "Upgrade saml2-js",
      "diff": "ZGlmZiAtLWdpdCBhL3lhcm4ubG9jayBiL3lhcm4ubG9jawppbmRleCAwZWNjOTJmLi43ZmE0NTU0IDEwMDY0NAotLS0gYS95YXJuLmxvY2sKKysrIGIveWFybi5sb2NrCkBAIC0yLDEwMyArMiwxMjQgQEAKICMgeWFybiBsb2NrZmlsZSB2MQogCiAKLWFzeW5jQH4wLjIuNzoKLSAgdmVyc2lvbiAiMC4yLjEwIgotICByZXNvbHZlZCAiaHR0cDovL3JlZ2lzdHJ5Lm5wbWpzLm9yZy9hc3luYy8tL2FzeW5jLTAuMi4xMC50Z3ojYjZiYmUwYjA2NzRiOWQ3MTk3MDhjYTM4ZGU4YzIzN2NiNTI2YzNkMSIKLQotYXN5bmNAfjEuNS4yOgotICB2ZXJzaW9uICIxLjUuMiIKLSAgcmVzb2x2ZWQgImh0dHA6Ly9yZWdpc3RyeS5ucG1qcy5vcmcvYXN5bmMvLS9hc3luYy0xLjUuMi50Z3ojZWM2YTYxYWU1NjQ4MGMwYzNjYjI0MWM5NTYxOGUyMDg5MmY5NjcyYSIKK2FzeW5jQF4yLjEuNSwgYXN5bmNAXjIuNS4wOgorICB2ZXJzaW9uICIyLjYuMSIKKyAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20vYXN5bmMvLS9hc3luYy0yLjYuMS50Z3ojYjI0NWEyM2NhNzE5MzAwNDRlYzUzZmE0NmFhMDBhM2U4N2M2YTYxMCIKKyAgaW50ZWdyaXR5IHNoYTUxMi1mTkVpTDIrQVp0NkFsQXcvMjlDcjBVRGU0c1JBSENwRUhoNTRXTXorQmI3UWZOY0Z3NGgzbG9vZnlKcExlUXM0WXg3eXVxdS8yZExnTTVoS09zNkhsUT09CisgIGRlcGVuZGVuY2llczoKKyAgICBsb2Rhc2ggIl40LjE3LjEwIgogCi1kZWJ1Z0BeMS4wLjQ6Ci0gIHZlcnNpb24gIjEuMC41IgotICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS9kZWJ1Zy8tL2RlYnVnLTEuMC41LnRneiNmNzI0MTIxNzQzMGY5OWRlYzRjMmI0NzNlYWI5MjIyOGU4NzRjMmFjIgorZGVidWdAXjIuNi4wOgorICB2ZXJzaW9uICIyLjYuOSIKKyAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20vZGVidWcvLS9kZWJ1Zy0yLjYuOS50Z3ojNWQxMjg1MTVkZjEzNGZmMzI3ZTkwYTRjOTNmNGUwNzdhNTM2MzQxZiIKKyAgaW50ZWdyaXR5IHNoYTUxMi1iQzdFbHJkSmFKblBiQVArMUVvdFl2cVpzYjNlY2w1d2k2QmZpNkJKVFVjTm93cDZjdnNwZzBqWHpuUlRLRGptL0U3QWRnRkJWZUFQVk1OY0tHc0hNQT09CiAgIGRlcGVuZGVuY2llczoKICAgICBtcyAiMi4wLjAiCiAKLWVqc0B+MC44LjM6Ci0gIHZlcnNpb24gIjAuOC44IgotICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS9lanMvLS9lanMtMC44LjgudGd6I2ZmZGM1NmRjYzM1ZDAyOTI2ZGQ1MGFkMTM0MzliYmM1NDA2MWQ1OTgiCitlanNAXjIuNS42OgorICB2ZXJzaW9uICIyLjYuMSIKKyAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20vZWpzLy0vZWpzLTIuNi4xLnRneiM0OThlYzBkNDk1NjU1YWJjNmYyM2NkNjE4NjhkOTI2NDY0MDcxYWEwIgorICBpbnRlZ3JpdHkgc2hhNTEyLTB4eTRBL3R3ZnJSQ25raGZrOEVyRGk1RHFkQXNBcWVHeGh0NHhrQ1Vyc3ZoaGJRTnM3RSs0alYwQ043K05LSVkwYUhFNzIrWHZxdEJJWHpEMzFaYlhRPT0KKworbG9kYXNoLW5vZGVAfjIuNC4xOgorICB2ZXJzaW9uICIyLjQuMSIKKyAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20vbG9kYXNoLW5vZGUvLS9sb2Rhc2gtbm9kZS0yLjQuMS50Z3ojZWE4MmY3YjEwMGM3MzNkMWE0MmFmNzY4MDFlNTA2MTA1ZTJhODBlYyIKKyAgaW50ZWdyaXR5IHNoYTEtNm9MM3NRREhNOUdrS3Zkb0FlVUdFRjRxZ093PQorCitsb2Rhc2hAXjQuMTcuMTA6CisgIHZlcnNpb24gIjQuMTcuMTEiCisgIHJlc29sdmVkICJodHRwczovL3JlZ2lzdHJ5Lnlhcm5wa2cuY29tL2xvZGFzaC8tL2xvZGFzaC00LjE3LjExLnRneiNiMzllYTYyMjllZjYwN2VjZDg5ZTJjOGRmMTI1MzY4OTFjYWM5YjhkIgorICBpbnRlZ3JpdHkgc2hhNTEyLWNRS2g4aWdvNVFVaFo3bGczOERZV0F4TXZqU0FLRzBBOHdHU1ZpbVAwN1NJVUVLMlVPK2FyU1JLYlJaV3RlbE10TjVWMEhrd2g1cnlPdG8vU3NoWUlnPT0KIAogbXNAMi4wLjA6CiAgIHZlcnNpb24gIjIuMC4wIgogICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS9tcy8tL21zLTIuMC4wLnRneiM1NjA4YWVhZGZjMDBiZTZjMjkwMWRmNWY5ODYxNzg4ZGUwZDU5N2M4IgorICBpbnRlZ3JpdHkgc2hhMS1WZ2l1cmZ3QXZtd3BBZDlmbUdGNGplRFZsOGc9CiAKLW5vZGUtZm9yZ2VAMC4yLjI0OgotICB2ZXJzaW9uICIwLjIuMjQiCi0gIHJlc29sdmVkICJodHRwczovL3JlZ2lzdHJ5Lnlhcm5wa2cuY29tL25vZGUtZm9yZ2UvLS9ub2RlLWZvcmdlLTAuMi4yNC50Z3ojZmE2Zjg0NmY0MmZhOTNmNjNhMGEzMGM5ZmJmZjdiNGUxMzBlMDg1OCIKK25vZGUtZm9yZ2VAXjAuNy4wOgorICB2ZXJzaW9uICIwLjcuNiIKKyAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20vbm9kZS1mb3JnZS8tL25vZGUtZm9yZ2UtMC43LjYudGd6I2ZkZjNiNDE4YWVlMWY5NGYwZWY2NDJjZDYzNDg2Yzc3Y2E5NzI0YWMiCisgIGludGVncml0eSBzaGE1MTItc29sMzBMVXB6MWpRRkJqT0t3Ymp4aWppRTNiNnBqZDc0WXdmRDBmSk9LUGpGK2ZPTktiMllnOHJZZ1M2K2JLNlZEbCsvd2ZyNElZcEM3akR6TFVJZnc9PQogCiBzYW1sMi1qc0BeMS41LjA6Ci0gIHZlcnNpb24gIjEuNS4wIgotICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS9zYW1sMi1qcy8tL3NhbWwyLWpzLTEuNS4wLnRneiNjMGQyMjY4YTE3OWU3MzI5ZDI5ZWIyNWFhODJkZjU1MDM3NzRiMGQ5IgorICB2ZXJzaW9uICIxLjEyLjQiCisgIHJlc29sdmVkICJodHRwczovL3JlZ2lzdHJ5Lnlhcm5wa2cuY29tL3NhbWwyLWpzLy0vc2FtbDItanMtMS4xMi40LnRneiNjMjg4ZjIwYmRhNmQyYjkxMDczYjE2Yzk0ZWE3MmYyMjM0OWFjM2IzIgorICBpbnRlZ3JpdHkgc2hhMS13b2p5QzlwdEs1RUhPeGJKVHFjdklqU2F3N009CiAgIGRlcGVuZGVuY2llczoKLSAgICBhc3luYyAifjEuNS4yIgotICAgIGRlYnVnICJeMS4wLjQiCi0gICAgdW5kZXJzY29yZSAifjEuNi4wIgotICAgIHhtbC1jcnlwdG8gIl4wLjguMSIKLSAgICB4bWwtZW5jcnlwdGlvbiAifjAuNy40IgotICAgIHhtbDJqcyAifjAuNC4xIgotICAgIHhtbGJ1aWxkZXIgIn4yLjEuMCIKLSAgICB4bWxkb20gIn4wLjEuMTkiCisgICAgYXN5bmMgIl4yLjUuMCIKKyAgICBkZWJ1ZyAiXjIuNi4wIgorICAgIHVuZGVyc2NvcmUgIl4xLjguMCIKKyAgICB4bWwtY3J5cHRvICJeMC4xMC4wIgorICAgIHhtbC1lbmNyeXB0aW9uICJeMC4xMS4wIgorICAgIHhtbDJqcyAiXjAuNC4wIgorICAgIHhtbGJ1aWxkZXIgIn4yLjIuMCIKKyAgICB4bWxkb20gIl4wLjEuMCIKIAogc2F4QD49MC42LjA6CiAgIHZlcnNpb24gIjEuMi40IgogICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS9zYXgvLS9zYXgtMS4yLjQudGd6IzI4MTYyMzRlMjM3OGJkZGM0ZTUzNTRmYWI1Y2FhODk1ZGY3MTAwZDkiCisgIGludGVncml0eSBzaGE1MTItTnFWRHY5VHBBTlVqRm0wTjh1TTVHeEwzNlVnS2k5L2F0WncreDdZRm5ROGNrd0ZHS3JsNHhYNHlXdHJleTNVSm01blAxa1VibllnTG9wcVdOU1JoV3c9PQogCi11bmRlcnNjb3JlQD49MS41Lng6Cit1bmRlcnNjb3JlQF4xLjguMDoKICAgdmVyc2lvbiAiMS45LjEiCiAgIHJlc29sdmVkICJodHRwczovL3JlZ2lzdHJ5Lnlhcm5wa2cuY29tL3VuZGVyc2NvcmUvLS91bmRlcnNjb3JlLTEuOS4xLnRneiMwNmRjZTM0YTBlNjhhN2JhYmMyOWIzNjViOGU3NGI4OTI1MjAzOTYxIgorICBpbnRlZ3JpdHkgc2hhNTEyLTUvNGV0bkNrZDljOGd3Z293aTUvb20vbVlPNWFqQ2FPZ2R6ai9vVyswZVFWOVd4S0JEWnc1K3ljbUttZWFUWGpJblMvVzBCenBHTG8yeFIyYUJ3WmRnPT0KIAotdW5kZXJzY29yZUB+MS42LjA6Ci0gIHZlcnNpb24gIjEuNi4wIgotICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS91bmRlcnNjb3JlLy0vdW5kZXJzY29yZS0xLjYuMC50Z3ojOGIzOGIxMGNhY2RlZjYzMzM3YjhiMjRlNGZmODZkNDVhZWE1MjlhOCIKLQoteG1sLWNyeXB0b0BeMC44LjE6Ci0gIHZlcnNpb24gIjAuOC41IgotICByZXNvbHZlZCAiaHR0cDovL3JlZ2lzdHJ5Lm5wbWpzLm9yZy94bWwtY3J5cHRvLy0veG1sLWNyeXB0by0wLjguNS50Z3ojMmJiY2ZiM2ViMzNmM2E4MmEyMThiODIyYmY2NzJiNmIxYzIwZTUzOCIKK3htbC1jcnlwdG9AXjAuMTAuMDoKKyAgdmVyc2lvbiAiMC4xMC4xIgorICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS94bWwtY3J5cHRvLy0veG1sLWNyeXB0by0wLjEwLjEudGd6I2Y4MzJmNzRjY2Y1NmYyNGFmY2FlMTE2M2ExZmNhYjQ0ZDk2Nzc0YTgiCisgIGludGVncml0eSBzaGExLStETDNUTTlXOGtyOHJoRmpvZnlyUk5sbmRLZz0KICAgZGVwZW5kZW5jaWVzOgogICAgIHhtbGRvbSAiPTAuMS4xOSIKICAgICB4cGF0aC5qcyAiPj0wLjAuMyIKIAoteG1sLWVuY3J5cHRpb25AfjAuNy40OgotICB2ZXJzaW9uICIwLjcuNCIKLSAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20veG1sLWVuY3J5cHRpb24vLS94bWwtZW5jcnlwdGlvbi0wLjcuNC50Z3ojNDI3OTFlYzY0ZDU1NmQyNDU1ZGNiOWRhMGE1NDEyMzY2NWFjNjVjNyIKK3htbC1lbmNyeXB0aW9uQF4wLjExLjA6CisgIHZlcnNpb24gIjAuMTEuMiIKKyAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20veG1sLWVuY3J5cHRpb24vLS94bWwtZW5jcnlwdGlvbi0wLjExLjIudGd6I2MyMTdmNTUwOTU0N2UzNGI1MDBiODI5ZjJjMGJjYTg1Y2NhNzNhMjEiCisgIGludGVncml0eSBzaGE1MTItalZ2RVM3aTVvdmRPN04rTmpnbmNBMzI2eFlLamhxZUFubnZJZ1JuWTdST0xDZkZxRURMd1AwU3hwLzMwU0hHMEFYUVYxMDQ4VDV5aW5PRnl2d0dGemc9PQogICBkZXBlbmRlbmNpZXM6Ci0gICAgYXN5bmMgIn4wLjIuNyIKLSAgICBlanMgIn4wLjguMyIKLSAgICBub2RlLWZvcmdlICIwLjIuMjQiCisgICAgYXN5bmMgIl4yLjEuNSIKKyAgICBlanMgIl4yLjUuNiIKKyAgICBub2RlLWZvcmdlICJeMC43LjAiCiAgICAgeG1sZG9tICJ+MC4xLjE1IgotICAgIHhwYXRoICIwLjAuNSIKKyAgICB4cGF0aCAiMC4wLjI3IgogCi14bWwyanNAfjAuNC4xOgoreG1sMmpzQF4wLjQuMDoKICAgdmVyc2lvbiAiMC40LjE5IgogICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS94bWwyanMvLS94bWwyanMtMC40LjE5LnRneiM2ODZjMjBmMjEzMjA5ZTk0YWJmMGQxYmNmMWVmYWEyOTFjNzgyN2E3IgorICBpbnRlZ3JpdHkgc2hhNTEyLWVzWm5KWkpPaUpSOXdXS015dXZTRTF5NkRxNUxDdUphbnFoeHNsSDJieE02ZHVhaE5aK0hNcENMaEJRR1prYlg2eFJmOHgxWTJlSmxndDJxM3FvNDlRPT0KICAgZGVwZW5kZW5jaWVzOgogICAgIHNheCAiPj0wLjYuMCIKICAgICB4bWxidWlsZGVyICJ+OS4wLjEiCiAKLXhtbGJ1aWxkZXJAfjIuMS4wOgotICB2ZXJzaW9uICIyLjEuMCIKLSAgcmVzb2x2ZWQgImh0dHA6Ly9yZWdpc3RyeS5ucG1qcy5vcmcveG1sYnVpbGRlci8tL3htbGJ1aWxkZXItMi4xLjAudGd6IzZkZGFlMzE2ODNiNmRmMTIxMDBiMjlmYzhhMGQ0ZjQ2MzQ5YWJiZWQiCit4bWxidWlsZGVyQH4yLjIuMDoKKyAgdmVyc2lvbiAiMi4yLjEiCisgIHJlc29sdmVkICJodHRwczovL3JlZ2lzdHJ5Lnlhcm5wa2cuY29tL3htbGJ1aWxkZXIvLS94bWxidWlsZGVyLTIuMi4xLnRneiM5MzI2NDMwZjEzMGQ4NzQzNWQ0YzQwODY2NDNhYTI5MjZlMTA1YTMyIgorICBpbnRlZ3JpdHkgc2hhMS1reVpERHhNTmgwTmRURUNHWkRxaWttNFFXakk9CiAgIGRlcGVuZGVuY2llczoKLSAgICB1bmRlcnNjb3JlICI+PTEuNS54IgorICAgIGxvZGFzaC1ub2RlICJ+Mi40LjEiCiAKIHhtbGJ1aWxkZXJAfjkuMC4xOgogICB2ZXJzaW9uICI5LjAuNyIKLSAgcmVzb2x2ZWQgImh0dHA6Ly9yZWdpc3RyeS5ucG1qcy5vcmcveG1sYnVpbGRlci8tL3htbGJ1aWxkZXItOS4wLjcudGd6IzEzMmVlNjNkMmVjNTU2NWM1NTdlMjBmNGMyMmRmOWFjYTY4NmIxMGQiCisgIHJlc29sdmVkICJodHRwczovL3JlZ2lzdHJ5Lnlhcm5wa2cuY29tL3htbGJ1aWxkZXIvLS94bWxidWlsZGVyLTkuMC43LnRneiMxMzJlZTYzZDJlYzU1NjVjNTU3ZTIwZjRjMjJkZjlhY2E2ODZiMTBkIgorICBpbnRlZ3JpdHkgc2hhMS1FeTdtUFM3RlZseFZmaUQwd2kzNXJLYUdzUTA9CiAKIHhtbGRvbUA9MC4xLjE5OgogICB2ZXJzaW9uICIwLjEuMTkiCiAgIHJlc29sdmVkICJodHRwczovL3JlZ2lzdHJ5Lnlhcm5wa2cuY29tL3htbGRvbS8tL3htbGRvbS0wLjEuMTkudGd6IzYzMWZjMDc3NzZlZmQ4NDExOGJmMjUxNzFiMzdlZDRkMDc1YTBhYmMiCisgIGludGVncml0eSBzaGExLVl4L0FkM2J2MkVFWXZ5VVhHemZ0VFFkYUNydz0KIAoteG1sZG9tQH4wLjEuMTUsIHhtbGRvbUB+MC4xLjE5OgoreG1sZG9tQF4wLjEuMCwgeG1sZG9tQH4wLjEuMTU6CiAgIHZlcnNpb24gIjAuMS4yNyIKICAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20veG1sZG9tLy0veG1sZG9tLTAuMS4yNy50Z3ojZDUwMWY5N2IzYmRiNDAzYWY4ZWY5ZWNjMjA1NzMxODdhYWRhYzBlOSIKKyAgaW50ZWdyaXR5IHNoYTEtMVFINWV6dmJRRHI0NzU3TUlGY3hoNnJhd09rPQogCiB4cGF0aC5qc0A+PTAuMC4zOgogICB2ZXJzaW9uICIxLjEuMCIKICAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20veHBhdGguanMvLS94cGF0aC5qcy0xLjEuMC50Z3ojMzgxNmE0NGVkNGJiMzUyMDkxMDgzZDAwMmEzODNkZDUxMDRhNWZmMSIKKyAgaW50ZWdyaXR5IHNoYTUxMi1qZytxa2ZTNEs4RTc5NjVzcWFVbDhtUm5nWGlLYjNXWkdmT05nRTE4cHIwM0ZVUWl1U1Y2RytFajR0UzU1QitySVFTRkVJdzNwaGRWQVE0cFBxTldmUT09CiAKLXhwYXRoQDAuMC41OgotICB2ZXJzaW9uICIwLjAuNSIKLSAgcmVzb2x2ZWQgImh0dHBzOi8vcmVnaXN0cnkueWFybnBrZy5jb20veHBhdGgvLS94cGF0aC0wLjAuNS50Z3ojNDU0MDM2ZjZlZjBmM2RmNWFmNWQ0YmE0YTExOWZiNzU2NzRiM2U2YyIKK3hwYXRoQDAuMC4yNzoKKyAgdmVyc2lvbiAiMC4wLjI3IgorICByZXNvbHZlZCAiaHR0cHM6Ly9yZWdpc3RyeS55YXJucGtnLmNvbS94cGF0aC8tL3hwYXRoLTAuMC4yNy50Z3ojZGQzNDIxZmJkY2M1NjQ2YWMzMmM0ODUzMWI0ZDdlOWQwYzJjZmE5MiIKKyAgaW50ZWdyaXR5IHNoYTUxMi1mZzAzV1J4dGtDVjZvaENsZVBOQUVDWXNtcEtLVHY1TDh5L1gzRG4xaFFyZWMzUE94MmpIWi8wUDJxUTZIdnNyVTFCbWVxWGNvZjNOR0d1ZUc2THh3UT09Cg=="
    }
  ]
}
```

Here is the description of the report file structure nodes and their meaning:

| Report JSON node                                     | Function |
|------------------------------------------------------|----------|
| `version`                                            | Current version of the report syntax. |
| `vulnerabilities`                                    | Array of vulnerability objects. |
| `vulnerabilities[].category`                         | Describes where this vulnerability belongs (SAST, Dependency Scanning etc.). For Dependency Scanning, it will always be `dependency_scanning`. |
| `vulnerabilities[].name`                             | Name of the vulnerability, this must not include occurrence's specific information. |
| `vulnerabilities[].message`                          | A short text that describes the vulnerability, it may include occurrence's specific information. |
| `vulnerabilities[].description`                      | A long text that describes the vulnerability. |
| `vulnerabilities[].cve`                              | A fingerprint string value that represents a concrete occurrence of the vulnerability. Is used to determine whether two vulnerability occurrences are same or different. May not be 100% accurate. And **this is NOT a [CVE](https://cve.mitre.org/)**. |
| `vulnerabilities[].severity`                         | Describes how much the vulnerability impacts the software. Possible values: `Info`, `Unknown`, `Low`, `Medium`, `High`, `Critical`. |
| `vulnerabilities[].confidence`                       | Describes how reliable the vulnerability's assessment is. Possible values: `Ignore`, `Unknown`, `Experimental`, `Low`, `Medium`, `High`, `Confirmed`. |
| `vulnerabilities[].solution`                         | Explains how to fix the vulnerability. |
| `vulnerabilities[].scanner`                          | A node that describes the analyzer used find this vulnerability. |
| `vulnerabilities[].scanner.id`                       | Id of the scanner as a snake_case string (mandatory). |
| `vulnerabilities[].scanner.name`                     | Name of the scanner, for display purposes (mandatory). |
| `vulnerabilities[].location`                         | A node that tells which class and/or method is affected by the vulnerability. | 
| `vulnerabilities[].location.file`                    | File is the path relative to the search path. |
| `vulnerabilities[].location.dependency`              | A node that describes the dependency of a project where the vulnerability is located. |
| `vulnerabilities[].location.dependency.package.name` | Name of the dependency package where the vulnerability is located. |
| `vulnerabilities[].location.dependency.version`      | Version of the vulnerable dependency package. |
| `vulnerabilities[].identifiers`                      | An array of references that identify a vulnerability on internal or external DBs. |
| `vulnerabilities[].identifiers[].type`               | Type of the identifier. Possible values: common identifier types (among `cve`, `cwe`, `osvdb`, and `usn`) or analyzer-dependent ones (e.g. `gemnasium` for [Gemnaisum analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/)). |
| `vulnerabilities[].identifiers[].name`               | Name of the identifier for display purpose. |
| `vulnerabilities[].identifiers[].value`              | Value of the identifier for matching purpose. |
| `vulnerabilities[].identifiers[].url`                | URL to identifier's documentation. |
| `vulnerabilities[].identifiers[].links`              | An array of references to external documentation pieces or articles that describe the vulnerability further. |
| `vulnerabilities[].identifiers[].links[].name`       | Name of the vulnerability details link (optional). |
| `vulnerabilities[].identifiers[].links[].url`        | URL of the vulnerability details document (mandatory). |
| `remediations`                                       | An array of objects containing information on cured vulnerabilities along with patch diffs to apply. |
| `remediations[].fixes`                               | An array of strings that represent references to vulnerabilities fixed by this particular remediation. |
| `remediations[].fixes[].cve`                         | A string value that describes a fixed vulnerability occurrence in the same format as `vulnerabilities[].cve`. |
| `remediations[].summary`                             | Overview of how the vulnerabilities have been fixed. |
| `remediations[].diff`                                | base64-encoded remediation code diff, compatible with `git apply`. |

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups and projects. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).

## Contributing to the vulnerability database

You can search the [gemnasium-db](https://gitlab.com/gitlab-org/security-products/gemnasium-db) project
to find a vulnerability in the Gemnasium database.
You can also [submit new vulnerabilities](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).