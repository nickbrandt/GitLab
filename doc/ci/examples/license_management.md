# Dependencies license management with GitLab CI/CD **[ULTIMATE]**

These examples show how to run License Management scanning on your project's dependencies by using GitLab CI/CD.

## Prerequisites

To run a License Management scanning job, you need GitLab Runner with
[docker executor](https://docs.gitlab.com/runner/executors/docker.html).

## Configuring with templates

Since GitLab 11.9, a CI/CD template with the default License Management scanning job definition is provided as a part of your GitLab installation.
This section describes how to use it and customize its execution.

### Using job definition template

CAUTION: **Caution:**
The CI/CD template for job definition is supported on GitLab 11.9 and later versions.
For earlier versions, use the [manual job definition](#manual-job-definition).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` using [the CI/CD template](../../ci/yaml/README.md#includetemplate) for License Management:

```yaml
include:
  template: License-Management.gitlab-ci.yml
```

### Scanning results

The above example will create a `license_management` job in your CI/CD pipeline
and scan your dependencies to find their licenses. The report will be saved as a
[License Management report artifact](../../ci/yaml/README.md#artifactsreportslicense_management-ultimate)
that you can later download and analyze.
Due to implementation limitations we always take the latest License Management artifact available.

TIP: **Tip:**
For [GitLab Ultimate][ee] users, this information will
be automatically extracted and shown right in the merge request widget.
[Learn more on License Management in merge requests](../../user/project/merge_requests/license_management.md).

### Customizing the template

#### Install custom project dependencies

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
include:
  template: License-Management.gitlab-ci.yml
  
variables:
  LICENSE_MANAGEMENT_SETUP_CMD: ./my-custom-install-script.sh
```

In this example, `my-custom-install-script.sh` is a shell script at the root of the project.

#### Overriding job definition

If you want to override the job definition (for example, change properties like `variables` or `dependencies`), you need to declare
its definition after the template inclusion and specify any additional keys under it. For example:

```yaml
include:
  template: License-Management.gitlab-ci.yml

license_management:
  stage: my-custom-stage
```

## Manual job definition

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions _(although it's preferred to use 
[the job definition template](#using-job-definition-template) since 11.9)_.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

If you are using GitLab prior to 11.9, you can define it manually using the following snippet:

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

Install custom project dependencies via `SETUP_CMD` variable:

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
