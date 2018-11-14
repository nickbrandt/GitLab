# Dependency Scanning with GitLab CI/CD **[ULTIMATE]**

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

This example shows how to run Dependency Scanning on your
project's dependencies by using GitLab CI/CD.


First, you need GitLab Runner with
[docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-executor).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` that
generates the expected report:

```yaml
dependency_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - docker run
        --env DEP_SCAN_DISABLE_REMOTE_CHECKS="${DEP_SCAN_DISABLE_REMOTE_CHECKS:-false}"
        --volume "$PWD:/code"
        --volume /var/run/docker.sock:/var/run/docker.sock
        "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$SP_VERSION" /code
  artifacts:
    reports:
      dependency_scanning: gl-dependency-scanning-report.json
```

The above example will create a `dependency_scanning` job in your CI/CD pipeline
and scan your dependencies for possible vulnerabilities. The report will be saved as a
[Dependency Scanning report artifact](../../ci/yaml/README.md#artifactsreportsdependency_scanning)
that you can later download and analyze.
Due to implementation limitations we always take the latest Dependency Scanning artifact available.

The results are sorted by the priority of the vulnerability:

1. High
1. Medium
1. Low
1. Unknown
1. Everything else

Behind the scenes, the [GitLab Dependency Scanning Docker image](https://gitlab.com/gitlab-org/security-products/dependency-scanning)
is used to detect the languages/package managers and in turn runs the matching scan tools.

Some security scanners require to send a list of project dependencies to GitLab
central servers to check for vulnerabilities. To learn more about this or to
disable it, check the [GitLab Dependency Scanning documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#remote-checks).

TIP: **Tip:**
For [GitLab Ultimate][ee] users, this information will
be automatically extracted and shown right in the merge request widget.
[Learn more on Dependency Scanning in merge requests](../../user/project/merge_requests/dependency_scanning.md).

## Supported languages and package managers

See [the full list of supported languages and package managers](../../user/project/merge_requests/dependency_scanning.md#supported-languages-and-frameworks).

## Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, Dependency Scanning job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained they have been deprecated
and may be removed in next major release, GitLab 12.0.
You are advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

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
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - docker run
        --env DEP_SCAN_DISABLE_REMOTE_CHECKS="${DEP_SCAN_DISABLE_REMOTE_CHECKS:-false}"
        --volume "$PWD:/code"
        --volume /var/run/docker.sock:/var/run/docker.sock
        "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$SP_VERSION" /code
  artifacts:
    paths: [gl-dependency-scanning-report.json]
```

[ee]: https://about.gitlab.com/pricing/
