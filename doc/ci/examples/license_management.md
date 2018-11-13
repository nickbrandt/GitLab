# Dependencies license management with GitLab CI/CD **[ULTIMATE]**

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

This example shows how to run the License Management tool on your
project's dependencies by using GitLab CI/CD.

First, you need GitLab Runner with
[docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-executor).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` that
generates the expected report:

```yaml
license_management:
  image:
    name: "registry.gitlab.com/gitlab-org/security-products/license-management:$CI_SERVER_VERSION_MAJOR-$CI_SERVER_VERSION_MINOR-stable"
    entrypoint: [""]
  stage: test
  allow_failure: true
  script:
    - /run.sh analyze .
  artifacts:
    reports:
      license_management: gl-license-management-report.json
```

The above example will create a `license_management` job in your CI/CD pipeline
and scan your dependencies to find their licenses. The report will be saved as a
[License Management report artifact](../../ci/yaml/README.md#artifactsreportslicense_management)
that you can later download and analyze.
Due to implementation limitations we always take the latest License Management artifact available.

## Install custom project dependencies

> Introduced in GitLab Ultimate 11.4.

The `license_management` image already embeds many auto-detection scripts, languages, 
and packages. Nevertheless, it's almost impossible to cover all cases, for all projects.
That's why sometimes it's necessary to install extra packages, or to have extra steps
in the project automated setup, like the download and installation of a certificate.
For that, a `SETUP_CMD` environment variable can be passed to the container,
with the required commands to run before license detection.

If present, this variable will override the setup step necessary to install all the packages
of your application (ex: for a project with a `Gemfile`, the setup step will be `bundle install`).

Example:

```yaml
license_management:
  image:
    name: "registry.gitlab.com/gitlab-org/security-products/license-management:$CI_SERVER_VERSION_MAJOR-$CI_SERVER_VERSION_MINOR-stable"
    entrypoint: [""]
  stage: test
  variables:
    SETUP_CMD: ./my-custom-install-script.sh
  allow_failure: true
  script:
    - /run.sh analyze .
  artifacts:
    reports:
      license_management: gl-license-management-report.json
```

In this example, `my-custom-install-script.sh` is a shell script at the root of the project.

TIP: **Tip:**
For [GitLab Ultimate][ee] users, this information will
be automatically extracted and shown right in the merge request widget.
[Learn more on License Management in merge requests](../../user/project/merge_requests/license_management.md).

## Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, License Management job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained they have been deprecated
and may be removed in next major release, GitLab 12.0.
You are advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the job should look like:

```yaml
license_management:
  image:
    name: "registry.gitlab.com/gitlab-org/security-products/license-management:$CI_SERVER_VERSION_MAJOR-$CI_SERVER_VERSION_MINOR-stable"
    entrypoint: [""]
  stage: test
  allow_failure: true
  script:
    - /run.sh analyze .
  artifacts:
    paths: [gl-license-management-report.json]
```

[ee]: https://about.gitlab.com/pricing/
