# Dependencies license management with GitLab CI/CD **[ULTIMATE]**

NOTE: **Note:**
In order to use this tool, a [GitLab Ultimate][ee] license
is needed.

This example shows how to run the License Management tool on your
project's dependencies by using GitLab CI/CD.

You can add a new job to `.gitlab-ci.yml`, called `license_management`:

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

The above example will create a `license_management` job in the `test` stage
and will create the required report artifact. Check the [Auto-DevOps
template](https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Auto-DevOps.gitlab-ci.yml)
for a full reference.

## Install custom project dependencies

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
    SETUP_CMD=./my-custom-install-script.sh
  allow_failure: true
  script:
    - /run.sh analyze .
  artifacts:
    paths: [gl-license-management-report.json]
```

In this example, `my-custom-install-script.sh` is a shell script at the root of the project.

TIP: **Tip:**
Starting with [GitLab Ultimate][ee] 11.0, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI job must be named `license_management` and the artifact path must be
`gl-license-management-report.json`. Make sure your pipeline has a stage named `test`,
or specify another existing stage inside the `license_management` job.
[Learn more on license management results shown in merge requests](../../user/project/merge_requests/license_management.md).


[ee]: https://about.gitlab.com/pricing/
