# License Management **[ULTIMATE]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/5483)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.0.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can search your project dependencies for their licenses
using License Management.

You can take advantage of License Management by either [including the CI job](../../../ci/examples/license_management.md) in
your existing `.gitlab-ci.yml` file or by implicitly using
[Auto License Management](../../../topics/autodevops/index.md#auto-license-management-ultimate)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

In addition, you can [manually approve or blacklist](#manual-license-management) licenses in the project's settings.

Going a step further, GitLab can show the licenses list right in the merge
request widget area, highlighting the presence of licenses you don't want to use, or new
ones that need a decision.

## Use cases

It helps you find what licenses your project uses in its dependencies, and decide for each of then
whether to allow it or forbid it. For example, your application is using an external (open source)
library whose license is incompatible with yours.

## Supported languages and package managers

The following languages and package managers are supported.

| Language   | Package managers                                                  |
|------------|-------------------------------------------------------------------|
| JavaScript | [Bower](https://bower.io/), [npm](https://www.npmjs.com/)         |
| Go         | [Godep](https://github.com/tools/godep), go get                   |
| Java       | [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/) |
| .NET       | [Nuget](https://www.nuget.org/)                                   |
| Python     | [pip](https://pip.pypa.io/en/stable/)                             |
| Ruby       | [gem](https://rubygems.org/)                                      |

## How it works

First of all, you need to define a job in your `.gitlab-ci.yml` file that generates the
[License Management report artifact](../../../ci/yaml/README.md#artifactsreportslicense_management).
For more information on how the License Management job should look like, check the
example on [Dependencies license management with GitLab CI/CD](../../../ci/examples/license_management.md).

GitLab then checks this report, compares the licenses between the source and target
branches, and shows the information right on the merge request.
Blacklisted licenses will be clearly visible, as well as new licenses which
need a decision from you.

>**Note:**
If the license management report doesn't have anything to compare to, no information
will be displayed in the merge request area. That is the case when you add the
`license_management` job in your `.gitlab-ci.yml` for the first time.
Consecutive merge requests will have something to compare to and the license
management report will be shown properly.

![License Management Widget](img/license_management.png)

If you are a project or group Maintainer, you can click on a license to be given
the choice to approve it or blacklist it.

![License approval decision](img/license_management_decision.png)

From the project's settings:

- The list of licenses and their status can be managed.
- Licenses can be [manually approved or blacklisted](#manual-license-management).

![License Management Settings](img/license_management_settings.png)

### Manual license management

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/5940)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.4.

Licenses can be manually approved or blacklisted in a project's settings.

To approve or blacklist a license:

1. Navigate to the project's **Settings > CI/CD**.
1. Expand the **License Management** section and click the **Add a license** button.
1. In the **License name** dropdown, either:
    - Select one of the available licenses. You can search for licenses in the field
   at the top of the list.
    - Enter arbitrary text in the field at the top of the list. This will cause the text to be
    added as a license name to the list.
1. Select the **Approve** or **Blacklist** radio button to approve or blacklist respectively
   the selected license.

## License Management report under pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/5491)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.2.

From your project's left sidebar, navigate to **CI/CD > Pipelines** and click on the
pipeline ID that has a `license_management` job to see the Licenses tab with the listed
licenses (if any).

![License Management Pipeline Tab](img/license_management_pipeline_tab.png)
