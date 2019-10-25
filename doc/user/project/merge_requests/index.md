---
type: index, reference, concepts
---

# Merge requests

Merge requests allow you to visualize and collaborate on the proposed changes
to source code that exist as commits on a given Git branch.

![Merge request view](img/merge_request.png)

## Overview

A Merge Request (**MR**) is the basis of GitLab as a code collaboration
and version control platform.
It is as simple as the name implies: a _request_ to _merge_ one branch into another.

With GitLab merge requests, you can:

- Compare the changes between two [branches](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell#_git_branching)
- [Review and discuss](../../discussions/index.md#threads) the proposed modifications inline
- Build, test, and deploy your code in a per-branch basis with built-in [GitLab CI/CD](../../../ci/README.md)
- View the deployment process through [Pipeline Graphs](../../../ci/pipelines.md#visualizing-pipelines)
- [Automatically close the issue(s)](../../project/issues/managing_issues.md#closing-issues-automatically) that originated the implementation proposed in the merge request
- Assign a [milestone](../../project/milestones/index.md) and track the development of a broader implementation
- Organize your issues and merge requests consistently throughout the project with [labels](../../project/labels.md)
- Add a time estimation and the time spent with that merge request with [Time Tracking](../time_tracking.md#time-tracking)
- [Allow collaboration](allow_collaboration.md) so members of the target project can push directly to the fork
- [Squash and merge](squash_and_merge.md) for a cleaner commit history

### Creating merge requests

While directly making changes to files in a branch of a repository is possible, it is not
the common workflow. In most cases, a user will [create a merge request](creating_merge_requests.md),
which is then [reviewed](reviewing_and_managing_merge_requests.md), updated, approved and merged into the target branch. This is
especially true for merging changes from a feature branch into the master branch.

[Creating merge requests](creating_merge_requests.md), as well as [reviewing and managing them](#reviewing-and-managing-merge-requests),
is a fundamental part of working with GitLab.

A large number of features relate directly to the merge request creation process:

| Features to help create merge requests                                                                                                        | Description                                                                                                                                    |
|-----------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| [Adding patches when creating a merge request via e-mail](creating_merge_requests.md#adding-patches-when-creating-a-merge-request-via-e-mail) |                                                                                                                                                |
| [Allow collaboration on merge requests across forks](creating_merge_requests.md#allow-collaboration-on-merge-requests-across-forks)           |                                                                                                                                                |
| [Create new merge requests by email](creating_merge_requests.md#create-new-merge-requests-by-email)                                           | Create new merge requests by sending an email to a user-specific email address.                                                                |
| [Deleting the source branch](creating_merge_requests.md#deleting-the-source-branch)                                                           | Select the "Delete source branch when merge request accepted" option and the source branch will be deleted when the merge request is merged.   |
| [Ignore whitespace changes in Merge Request diff view](creating_merge_requests.md#ignore-whitespace-changes-in-Merge-Request-diff-view)       |                                                                                                                                                |
| [Incrementally expand merge request diffs](creating_merge_requests.md#incrementally-expand-merge-request-diffs)                               |                                                                                                                                                |
| [Merge request approvals](merge_request_approvals.md) **(STARTER)**                                                                           | Set the number of necessary approvals and predefine a list of approvers that will need to approve every merge request in a project.            |
| [Merge Request Dependencies](merge_request_dependencies.md) **(PREMIUM)**                                                                     | Specify that a merge request depends on other merge requests, enforcing a desired order of merging.                   |
| [Merge request diff file navigation](creating_merge_requests.md#merge-request-diff-file-navigation)                                           |                                                                                                                                                |
| [Merge Requests for Confidential Issues](../issues/confidential_issues.md#merge-requests-for-confidential-issues)                             | Create merge requests to resolve confidential issues for preventing leakage or early release of sensitive data through regular merge requests. |
| [Multiple assignees](creating_merge_requests.md#multiple-assignees-starter) **(STARTER)**                                                     | Have multiple assignees for merge requests to indicate everyone that is reviewing or accountable for it.                                       |
| [Security reports](../../application_security/index.md) **(ULTIMATE)**                                                                        | GitLab can scan and report any vulnerabilities found in your project.                                                                          |
| [Squash and merge](creating_merge_requests.md#squash-and-merge)                                                                               | Squash all changes present in a merge request into a single commit when merging, to allow for a neater commit history.                         |
| [Work In Progress merge requests](creating_merge_requests.md#work-in-progress-merge-requests)                                                 | Prevent the merge request from being merged before it's ready |
| [Git push options](../push_options.md)                                                                                                        | Use Git push options to create or update merge requests when pushing changes to GitLab with Git, without needing to use the GitLab interface.  |
| [View changes between file versions](creating_merge_requests.md#view-changes-between-file-versions)                                                                     |                                                                                                                                                |

### Reviewing and managing merge requests

Once a merge request has been created and submitted, there are many powerful features
to aid in reviewing merge requests, to make sure only the changes you want are merged
into the repository.

Additionally, GitLab has many features that help maintainers manage the merge
requests in a project...

| Features to help review and manage merge requests                                                                                       | Description                                                                                                                                              |
|-----------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Bulk editing merge requests](../../project/bulk_editing.md)                                                                            |                                                                                                                                                          |
| [Cherry-pick changes](cherry_pick_changes.md)                                                                                           | Cherry-pick any commit in the UI by simply clicking the **Cherry-pick** button in a merged merge requests or a commit.                                   |
| [Commenting on any file line in merge requests](reviewing_and_managing_merge_requests.md#commenting-on-any-file-line-in-merge-requests) |                                                                                                                                                          |
| [Fast-forward merge requests](fast_forward_merge.md)                                                                                    | For a linear Git history and a way to accept merge requests without creating merge commits                                                               |
| [Find the merge request that introduced a change](versions.md)                                                                          | When viewing the commit details page, GitLab will link to the merge request(s) containing that commit.                                                   |
| [Live preview with Review Apps](reviewing_and_managing_merge_requests.md#live-preview-with-review-apps)                                 | Live preview the changes when Review Apps are configured for your project                                                                                |
| [Merge requests versions](versions.md)                                                                                                  | Select and compare the different versions of merge request diffs                                                                                         |
| [Merge when pipeline succeeds](merge_when_pipeline_succeeds.md)                                                                         | Set a merge request that looks ready to merge to merge automatically when CI pipeline succeeds.                                                          |
| [Perform a Review](../../discussions/index.md#merge-request-reviews-premium) **(PREMIUM)**                                              | Start a review in order to create multiple comments on a diff and publish them once you're ready.                                                        |
| [Pipeline status in merge requests](reviewing_and_managing_merge_requests.md#pipeline-status-in-merge-requests)                         |                                                                                                                                                          |
| [Post-merge pipeline status](reviewing_and_managing_merge_requests.md#post-merge-pipeline-status)                                       |                                                                                                                                                          |
| [Resolve conflicts](resolve_conflicts.md)                                                                                               | GitLab can provide the option to resolve certain merge request conflicts in the GitLab UI.                                                               |
| [Resolve threads in merge requests reviews](../../discussions/index.md)                                                                 | Keep track of the progress during a code review by resolving comments.                                                                                   |
| [Revert changes](revert_changes.md)                                                                                                     | Revert changes from any commit from within a merge request.                                                                                              |
| [Semi-linear history merge requests](reviewing_and_managing_merge_requests.md#semi-linear-history-merge-requests)                       | Enable semi-linear history merge requests as another security layer to guarantee the pipeline is passing in the target branch                            |
| [Suggest changes](../../discussions/index.md#suggest-changes)                                                                           | Add suggestions to change the content of merge requests directly into merge request threads, and easily apply them to the codebase directly from the UI. |
| [View group merge requests](reviewing_and_managing_merge_requests.md#view-group-merge-requests)                                         |                                                                                                                                                          |
| [View project merge requests](reviewing_and_managing_merge_requests.md#view-project-merge-requests)                                     |                                                                                                                                                          |
| [Authorization for merge requests](#authorization-for-merge-requests)                                                                   |                                                                                                                                                          |

### Testing and reports in merge requests

GitLab has the ability to do various tests on the changes included in a merge request,
and link to them directly from within the merge request page...

| Features that can display important information in merge requests                                      | Description                                                                                                                                                                                               |
|--------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Pipelines for merge requests](../../../ci/merge_request_pipelines/index.md)                           | Customize a specific pipeline structure for merge requests in order to speed the cycle up by running only important jobs.                                                                                 |
| [Multi-Project pipelines](../../../ci/multi_project_pipelines.md) **(PREMIUM)**                        | When you set up GitLab CI/CD across multiple projects, you can visualize the entire pipeline, including all cross-project interdependencies.                                                              |
| [Browser Performance Testing](browser_performance_testing.md) **(PREMIUM)**                            | Quickly determine the performance impact of pending code changes.                                                                                                                                         |
| [Code Quality](code_quality.md) **(STARTER)**                                                          | Analyze your source code quality using the [Code Climate](https://codeclimate.com/) analyzer and show the Code Climate report right in the merge request widget area.                                     |
| [JUnit test reports](../../../ci/junit_test_reports.md)                                                | Configure your CI jobs to use JUnit test reports, and let GitLab display a report on the merge request so that it’s easier and faster to identify the failure without having to check the entire job log. |
| [Metrics Reports](../../../ci/metrics_reports.md) **(PREMIUM)**                                        | Display the Metrics Report on the merge request so that it's fast and easy to identify changes to important metrics.                                                                                      |
| [Container Scanning](../../application_security/container_scanning/index.md) **(ULTIMATE)**            | Analyze your Docker images for vulnerabilities                                                                                                                                                            |
| [DAST (Dynamic Application Security Testing)](../../application_security/dast/index.md) **(ULTIMATE)** | Analyze your running web applications for vulnerabilities                                                                                                                                                 |
| [Dependency Scanning](../../application_security/dependency_scanning/index.md) **(ULTIMATE)**          | Analyze your dependencies for vulnerabilities                                                                                                                                                             |
| [License Compliance](../../application_security/license_compliance/index.md) **(ULTIMATE)**            | Manage the licenses of your dependencies                                                                                                                                                                  |
| [SAST (Static Application Security Testing)](../../application_security/sast/index.md) **(ULTIMATE)**  | Analyze your source code for vulnerabilities                                                                                                                                                              |

### Authorization for merge requests

There are two main ways to have a merge request flow with GitLab:

1. Working with [protected branches](../protected_branches.md) in a single repository
1. Working with forks of an authoritative project

[Learn more about the authorization for merge requests.](authorization_for_merge_requests.md)

### Checkout merge requests locally

Temporary.
