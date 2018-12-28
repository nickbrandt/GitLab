# Static Application Security Testing (SAST) **[ULTIMATE]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/3775)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.3.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can analyze your source code for known
vulnerabilities using Static Application Security Testing (SAST).

You can take advantage of SAST by either [including the CI job](../../../ci/examples/sast.md) in
your existing `.gitlab-ci.yml` file or by implicitly using
[Auto SAST](../../../topics/autodevops/index.md#auto-sast)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

Going a step further, GitLab can show the vulnerability list right in the merge
request widget area.

## Use cases

- Your code has a potentially dangerous attribute in a class, or unsafe code
  that can lead to unintended code execution.
- Your application is vulnerable to cross-site scripting (XSS) attacks that can
  be leveraged to unauthorized access to session data

## Supported languages and frameworks

The following languages and frameworks are supported.

| Language / framework  | Scan tool                                                                              |
|-----------------------|----------------------------------------------------------------------------------------|
| C/C++                 | [Flawfinder](https://www.dwheeler.com/flawfinder/)                                     |
| Python                | [bandit](https://github.com/PyCQA/bandit)                                              |
| Ruby on Rails         | [brakeman](https://brakemanscanner.org)                                                |
| Groovy (Gradle & Grail) | [find-sec-bugs](https://find-sec-bugs.github.io/)                                      |
| Java (Maven & Gradle) | [find-sec-bugs](https://find-sec-bugs.github.io/)                                      |
| Scala (sbt)           | [find-sec-bugs](https://find-sec-bugs.github.io/)                                      |
| Go                    | [Gosec](https://github.com/securego/gosec)                                             |
| PHP                   | [phpcs-security-audit](https://github.com/FloeDesignTechnologies/phpcs-security-audit) |
| .NET                  | [Security Code Scan](https://security-code-scan.github.io)                             |
| Node.js               | [NodeJsScan](https://github.com/ajinabraham/NodeJsScan)                                |

## How it works

First of all, you need to define a job in your `.gitlab-ci.yml` file that generates the
[SAST report artifact](../../../ci/yaml/README.md#artifactsreportssast).
For more information on how the SAST job should look like, check the
example on [Static Application Security Testing with GitLab CI/CD](../../../ci/examples/sast.md).

GitLab then checks this report, compares the found vulnerabilities between the source and target
branches, and shows the information right on the merge request.

![SAST Widget](img/sast.png)

## Security report under pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/3776)
in [GitLab Ultimate](https://about.gitlab.com/pricing) 10.6.

Visit any pipeline page which has a `sast` job and you will be able to see
the security report tab with the listed vulnerabilities (if any).

![Security Report](img/security_report.png)
