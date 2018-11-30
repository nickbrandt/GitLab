# Container Scanning **[ULTIMATE]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3672)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.4.

> [Introduced][ee-3672] in [GitLab Ultimate][ee] 10.4.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can analyze your Docker images for known
vulnerabilities using [Clair](https://github.com/coreos/clair),
a Vulnerability Static Analysis tool for containers.

You can take advantage of Container Scanning by either [including the CI job](../../../ci/examples/container_scanning.md) in
your existing `.gitlab-ci.yml` file or by implicitly using
[Auto Container Scanning](../../../topics/autodevops/index.md#auto-container-scanning)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

Going a step further, GitLab can show the vulnerability list right in the merge
request widget area.

![Container Scanning Widget](img/container_scanning.png)

## Use cases

If you distribute your application with Docker, then there's a great chance
that your image is based on other Docker images that may in turn contain some
known vulnerabilities that could be exploited.

Having an extra job in your pipeline that checks for those vulnerabilities,
and the fact that they are displayed inside a merge request, makes it very easy
to perform audits for your Docker-based apps.

## How it works

First of all, you need to define a job in your `.gitlab-ci.yml` file that generates the
[Container Scanning report artifact](../../../ci/yaml/README.md#artifactsreportscontainer_scanning).
For more information on how the Container Scanning job should look like, check the
example on [Container Scanning with GitLab CI/CD](../../../ci/examples/container_scanning.md).

GitLab then checks this report, compares the found vulnerabilities between the source and target
branches, and shows the information right on the merge request.
