# Dynamic Application Security Testing with GitLab CI/CD

[Dynamic Application Security Testing (DAST)](https://en.wikipedia.org/wiki/Dynamic_Application_Security_Testing)
is using the popular open source tool [OWASP ZAProxy](https://github.com/zaproxy/zaproxy)
to perform an analysis on your running web application.
Since it is based on [ZAP Baseline](https://github.com/zaproxy/zaproxy/wiki/ZAP-Baseline-Scan)
DAST will perform passive scanning only;
it will not actively attack your application.

It can be very useful combined with [Review Apps](../review_apps/index.md).

These examples show how to run DAST on your running web application by using GitLab CI/CD.

## Prerequisites

To run a DAST job, you need GitLab Runner with
[docker-in-docker executor](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode).

## Configuring with templates

Since GitLab 11.9, a CI/CD template with the default DAST job definition is provided as a part of your GitLab installation.
This section describes how to use it and customize its execution.

### Using job definition template

CAUTION: **Caution:**
The CI/CD template for job definition is supported on GitLab 11.9 and later versions.
For earlier versions, use the [manual job definition](#manual-job-definition).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` using [the CI/CD template](../../ci/yaml/README.md#includetemplate) for DAST:

```yaml
include:
  template: DAST.gitlab-ci.yml
```

The above example will create a `dast` job in your CI/CD pipeline which will run
the tests on the URL defined in the `DAST_WEBSITE` variable (change it to use your
own) and scan it for possible vulnerabilities.

It's also possible to authenticate the user before performing DAST checks:

```yaml
include:
  template: DAST.gitlab-ci.yml
  
variables:
  DAST_AUTH_URL: https://example.com/sign-in
  DAST_USERNAME: john.doe@example.com
  DAST_PASSWORD: john-doe-password
  DAST_USERNAME_FIELD: session[user] # the name of username field at the sign-in HTML form
  DAST_PASSWORD_FIELD: session[password] # the name of password field at the sign-in HTML form
```

### Scanning results

The report will be saved as a
[DAST report artifact](../yaml/README.md#artifactsreportsdast-ultimate)
that you can later download and analyze.
Due to implementation limitations we always take the latest DAST artifact available.

TIP: **Tip:**
For [GitLab Ultimate][ee] users, this information will
be automatically extracted and shown right in the merge request widget.
[Learn more on DAST in merge requests](../../user/project/merge_requests/dast.md).

### Customizing the template

You can customize DAST job execution in various ways of different granularity.

#### Scanning tool settings

DAST tool settings can be changed through environment variables. These variables are documented in the:
                                                                             
- Job definition [template](#using-job-definition-template).
- DAST [README](https://gitlab.com/gitlab-org/security-products/dast#settings).

The customization itself is performed by using the [`variables`](https://docs.gitlab.com/ee/ci/yaml/#variables)
parameter in the project's pipeline configuration file (`.gitlab-ci.yml`):

```yaml
include:
  template: DAST.gitlab-ci.yml

variables:
  DAST_TARGET_AVAILABILITY_TIMEOUT: 120
```

Because template is evaluated [before](../yaml/README.md#include) the pipeline configuration,
the last mention of the variable will take precedence.

#### Overriding job definition

If you want to override the job definition (for example, change properties like `variables` or `dependencies`), you need to declare
its definition after the template inclusion and specify any additional keys under it. For example:

```yaml
include:
  template: DAST.gitlab-ci.yml

dast:
  stage: dast # IMPORTANT: don't forget to add this
  variables:
    CI_DEBUG_TRACE: "true"
``` 

CAUTION: **Caution:**
As DAST job belongs to a separate `"dast"` stage that runs after all [default stages](../yaml/README.md#stages),
don't forget to add `stage: dast` entry when you override the template job definition. 

## Manual job definition

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions _(although it's preferred to use 
[the job definition template](#using-job-definition-template) since 11.9)_.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

If you are using GitLab prior to 11.9, you can define it manually using the following snippet:

```yaml
dast:
  image: registry.gitlab.com/gitlab-org/security-products/zaproxy
  variables:
    website: "https://example.com"
  allow_failure: true
  script:
    - mkdir /zap/wrk/
    - /zap/zap-baseline.py -J gl-dast-report.json -t $website || true
    - cp /zap/wrk/gl-dast-report.json .
  artifacts:
    reports:
      dast: gl-dast-report.json
```

where the `website` variable is supposed to hold the URL to run the tests against.

For an authenticated scan, use the following definition:

```yaml
dast:
  image: registry.gitlab.com/gitlab-org/security-products/zaproxy
  variables:
    website: "https://example.com"
    login_url: "https://example.com/sign-in"
    username: "john.doe@example.com"
    password: "john-doe-password"
  allow_failure: true
  script:
    - mkdir /zap/wrk/
    - /zap/zap-baseline.py -J gl-dast-report.json -t $website
        --auth-url $login_url
        --auth-username $username
        --auth-password $password || true
    - cp /zap/wrk/gl-dast-report.json .
  artifacts:
    reports:
      dast: gl-dast-report.json
```

See [zaproxy documentation](https://gitlab.com/gitlab-org/security-products/zaproxy)
to learn more about authentication settings.

## Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, DAST job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained they have been deprecated
and may be removed in next major release, GitLab 12.0.
You are advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the job should look like:

```yaml
dast:
  image: registry.gitlab.com/gitlab-org/security-products/zaproxy
  variables:
    website: "https://example.com"
  allow_failure: true
  script:
    - mkdir /zap/wrk/
    - /zap/zap-baseline.py -J gl-dast-report.json -t $website || true
    - cp /zap/wrk/gl-dast-report.json .
  artifacts:
    paths: [gl-dast-report.json]
``` 

[ee]: https://about.gitlab.com/pricing/
