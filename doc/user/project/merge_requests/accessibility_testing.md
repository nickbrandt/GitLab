---
type: reference, howto
---

# Accessibility Testing

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25144) in [GitLab Core](https://about.gitlab.com/pricing/) 12.8.

If your application offers a web interface and you are using
[GitLab CI/CD](../../../ci/README.md), you can quickly determine the accessibility
impact of pending code changes.

## Overview

GitLab uses [pa11y](https://pa11y.org/), a free and open source tool for
measuring the accessibility of web sites, and has built a simple
[CI template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml)
which outputs the results in a file called `accessibility`. This outputs
the accessibility violations, warnings, and notices for each page that is analyzed.

## Configuring Accessiblity Testing

This example shows how to run [pa11y](https://pa11y.org/)
on your code by using GitLab CI/CD with a plain node Docker image.

For GitLab 12.8 and later, to define the `performance` job, you must
[include](../../../ci/yaml/README.md#includetemplate) the
[`Accessibility.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml)
that's provided as a part of your GitLab installation.
For GitLab versions earlier than 12.8, you can copy and use the job as
defined in that template.

CAUTION: **Caution:**
The job definition provided by the template does not support Kubernetes yet.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  template: Verify/Accessibility.gitlab-ci.yml

a11y:
  variables:
    a11y_urls: https://example.com https://example.com/another-page
```

The above example will create a `a11y` job in your CI/CD pipeline and will run
Pa11y against the webpage you defined in `a11y_urls` to build a report.

The full HTML Pa11y report will be saved as an artifact that can be viewed directly in your browser.

It is not yet possible to pass configurations into Pa11y via CI configuration. To change anything,
copy the template to your CI file and make the desired edits.
