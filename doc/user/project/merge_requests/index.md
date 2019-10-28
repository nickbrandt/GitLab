---
type: index, reference
---

# Merge requests

Merge requests allow you to visualize and collaborate on the proposed changes
to source code that exist as commits on a given Git branch.

![Merge request view](img/merge_request.png)

A Merge Request (**MR**) is the basis of GitLab as a code collaboration and version
control platform. It is as simple as the name implies: a _request_ to _merge_ one
branch into another.

## Creating merge requests

While making changes to files in the `master` branch of a repository is possible, it is not
the common workflow. In most cases, a user will make changes in a [branch](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell#_git_branching),
then [create a merge request](creating_merge_requests.md) to request that the changes
be merged into another branch (often the `master` branch).

It is then [reviewed](#reviewing-and-managing-merge-requests), possibly updated after
discussions and suggestions, and finally approved and merged into the target branch.
Creating and reviewing merge requests is one of the most fundamental parts of working
with GitLab.

When [creating merge requests](creating_merge_requests.md), there are a number of features
to be aware of:

| Feature                                                                                                                                       | Description                                                                                                                                                                                |
|-----------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Adding patches when creating a merge request via e-mail](creating_merge_requests.md#adding-patches-when-creating-a-merge-request-via-e-mail) | Add commits to a merge request created by e-mail, by adding patches as e-mail attachments.                                                                                                 |
| [Allow collaboration on merge requests across forks](allow_collaboration.md)                                                                  | Allows the maintainers of an upstream project to collaborate on a fork, to make fixes or rebase branches before merging, reducing the back and forth of accepting community contributions. |
| [Automatically issue closing](../../project/issues/managing_issues.md#closing-issues-automatically)                                           | Set a merge request to close defined issues automatically, as soon as it is merged. |
| [Create new merge requests by email](creating_merge_requests.md#create-new-merge-requests-by-email)                                           | Create new merge requests by sending an email to a user-specific email address.                                                                                                            |
| [Deleting the source branch](creating_merge_requests.md#deleting-the-source-branch)                                                           | Select the "Delete source branch when merge request accepted" option and the source branch will be deleted when the merge request is merged.                                               |
| [Git push options](../push_options.md)                                                                                                        | Use Git push options to create or update merge requests when pushing changes to GitLab with Git, without needing to use the GitLab interface.                                              |
| [Ignore whitespace changes in Merge Request diff view](creating_merge_requests.md#ignore-whitespace-changes-in-Merge-Request-diff-view)       | Hide whitespace changes from the diff view for a to focus on more important changes.                                                                                                       |
| [Incrementally expand merge request diffs](creating_merge_requests.md#incrementally-expand-merge-request-diffs)                               | View the content directly above or below a change, to better understand the context of that change.                                                                                        |
| [Labels](../../project/labels.md)                                                                                                             | Organize your issues and merge requests consistently throughout the project.                                                   |
| [Merge request approvals](merge_request_approvals.md) **(STARTER)**                                                                           | Set the number of necessary approvals and predefine a list of approvers that will need to approve every merge request in a project.                                                        |
| [Merge Request Dependencies](merge_request_dependencies.md) **(PREMIUM)**                                                                     | Specify that a merge request depends on other merge requests, enforcing a desired order of merging.                                                                                        |
| [Merge request diff file navigation](creating_merge_requests.md#merge-request-diff-file-navigation)                                           | Quickly jump to any changed file within the diff view.                                                                                                                                     |
| [Merge Requests for Confidential Issues](../issues/confidential_issues.md#merge-requests-for-confidential-issues)                             | Create merge requests to resolve confidential issues for preventing leakage or early release of sensitive data through regular merge requests.                                             |
| [Milestones](../../project/milestones/index.md)                                                                                               | Track merge requests to achieve a broader goal in a certain period of time.              |
| [Multiple assignees](creating_merge_requests.md#multiple-assignees-starter) **(STARTER)**                                                     | Have multiple assignees for merge requests to indicate everyone that is reviewing or accountable for it.                                                                                   |
| [Security reports](../../application_security/index.md) **(ULTIMATE)**                                                                        | GitLab can scan and report any vulnerabilities found in your project.                                                                                                                      |
| [Squash and merge](squash_and_merge.md)                                                                                                       | Squash all changes present in a merge request into a single commit when merging, to allow for a neater commit history.                                                                     |
| [View changes between file versions](creating_merge_requests.md#view-changes-between-file-versions)                                           | View what will be changed when a merge request is merged.                                                                                                                                  |
| [Work In Progress merge requests](work_in_progress_merge_requests.md)                                                                         | Prevent the merge request from being merged before it's ready                                                                                                                              |

## Reviewing and managing merge requests

Once a merge request has been [created](#creating-merge-requests) and submitted, there
are many powerful features to improve the review process, and make sure only the changes
you want are merged into the repository.

It is also important to be able to view and manage all the merge requests in a group
or project. When [reviewing and managing merge requests](reviewing_and_managing_merge_requests.md),
there are a number of features to be aware of:

| Feature                                                                                                                                 | Description                                                                                                                                              |
|-----------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Allow collaboration](allow_collaboration.md)                                                                            | Allow the members of an upstream project to make small fixes or rebase branches before merging, reducing the back and forth of accepting external contributions. |
| [Bulk editing merge requests](../../project/bulk_editing.md)                                                                            | Update the attributes of multiple merge requests simultaneously.                                                                                         |
| [Cherry-pick changes](cherry_pick_changes.md)                                                                                           | Cherry-pick any commit in the UI by simply clicking the **Cherry-pick** button in a merged merge requests or a commit.                                   |
| [Commenting on any file line in merge requests](reviewing_and_managing_merge_requests.md#commenting-on-any-file-line-in-merge-requests) | Make comments directly on the exact line of a file you want to talk about.                                                                               |
| [Discuss changes in threads in merge requests reviews](../../discussions/index.md)                                                      | Keep track of the progress during a code review by making and resolving comments.                                                                                   |
| [Fast-forward merge requests](fast_forward_merge.md)                                                                                    | For a linear Git history and a way to accept merge requests without creating merge commits                                                               |
| [Find the merge request that introduced a change](versions.md)                                                                          | When viewing the commit details page, GitLab will link to the merge request(s) containing that commit.                                                   |
| [Live preview with Review Apps](reviewing_and_managing_merge_requests.md#live-preview-with-review-apps)                                 | Live preview the changes when Review Apps are configured for your project                                                                                |
| [Merge requests versions](versions.md)                                                                                                  | Select and compare the different versions of merge request diffs                                                                                         |
| [Merge when pipeline succeeds](merge_when_pipeline_succeeds.md)                                                                         | Set a merge request that looks ready to merge to merge automatically when CI pipeline succeeds.                                                          |
| [Perform a Review](../../discussions/index.md#merge-request-reviews-premium) **(PREMIUM)**                                              | Start a review in order to create multiple comments on a diff and publish them once you're ready.                                                        |
| [Pipeline status in merge requests](reviewing_and_managing_merge_requests.md#pipeline-status-in-merge-requests)                         | If using [GitLab CI/CD](../../../ci/README.md), see pre and post-merge pipelines information, and which deployments are in progress.                     |
| [Post-merge pipeline status](reviewing_and_managing_merge_requests.md#post-merge-pipeline-status)                                       | When a merge request is merged, see the post-merge pipeline status of the branch the merge request was merged into.                                      |
| [Resolve conflicts](resolve_conflicts.md)                                                                                               | GitLab can provide the option to resolve certain merge request conflicts in the GitLab UI.                                                               |
| [Revert changes](revert_changes.md)                                                                                                     | Revert changes from any commit from within a merge request.                                                                                              |
| [Semi-linear history merge requests](reviewing_and_managing_merge_requests.md#semi-linear-history-merge-requests)                       | Enable semi-linear history merge requests as another security layer to guarantee the pipeline is passing in the target branch                            |
| [Suggest changes](../../discussions/index.md#suggest-changes)                                                                           | Add suggestions to change the content of merge requests directly into merge request threads, and easily apply them to the codebase directly from the UI. |
| [Time Tracking](../time_tracking.md#time-tracking)                                                                           | Add a time estimation and the time spent with that merge request. |
| [View group merge requests](reviewing_and_managing_merge_requests.md#view-group-merge-requests)                                         | List and view the merge requests within a group.                                                                                                         |
| [View project merge requests](reviewing_and_managing_merge_requests.md#view-project-merge-requests)                                     | List and view the merge requests within a project.                                                                                                       |

## Testing and reports in merge requests

GitLab has the ability to test the changes included in a merge request, and display
or link to the results directly in the merge request page:

| Feature                                                                                                | Description                                                                                                                                                                                               |
|--------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Browser Performance Testing](browser_performance_testing.md) **(PREMIUM)**                            | Quickly determine the performance impact of pending code changes.                                                                                                                                         |
| [Code Quality](code_quality.md) **(STARTER)**                                                          | Analyze your source code quality using the [Code Climate](https://codeclimate.com/) analyzer and show the Code Climate report right in the merge request widget area.                                     |
| [Container Scanning](../../application_security/container_scanning/index.md) **(ULTIMATE)**            | Analyze your Docker images for vulnerabilities                                                                                                                                                            |
| [DAST (Dynamic Application Security Testing)](../../application_security/dast/index.md) **(ULTIMATE)** | Analyze your running web applications for vulnerabilities                                                                                                                                                 |
| [Dependency Scanning](../../application_security/dependency_scanning/index.md) **(ULTIMATE)**          | Analyze your dependencies for vulnerabilities                                                                                                                                                             |
| [Display arbitrary job artifacts](../../../ci/yaml/README.md#artifactsexpose_as)                       | Configure CI pipelines with the `artifacts:expose_as` parameter to directly link to selected [artifacts](../pipelines/job_artifacts.md) in merge requests.                                                |
| [GitLab CI/CD](../../../ci/README.md)                                                                  | Build, test, and deploy your code in a per-branch basis with built-in CI/CD. |
| [JUnit test reports](../../../ci/junit_test_reports.md)                                                | Configure your CI jobs to use JUnit test reports, and let GitLab display a report on the merge request so that it’s easier and faster to identify the failure without having to check the entire job log. |
| [License Compliance](../../application_security/license_compliance/index.md) **(ULTIMATE)**            | Manage the licenses of your dependencies                                                                                                                                                                  |
| [Metrics Reports](../../../ci/metrics_reports.md) **(PREMIUM)**                                        | Display the Metrics Report on the merge request so that it's fast and easy to identify changes to important metrics.                                                                                      |
| [Multi-Project pipelines](../../../ci/multi_project_pipelines.md) **(PREMIUM)**                        | When you set up GitLab CI/CD across multiple projects, you can visualize the entire pipeline, including all cross-project interdependencies.                                                              |
| [Pipelines for merge requests](../../../ci/merge_request_pipelines/index.md)                           | Customize a specific pipeline structure for merge requests in order to speed the cycle up by running only important jobs.                                                                                 |
| [Pipeline Graphs](../../../ci/pipelines.md#visualizing-pipelines)                                      | View the status of pipelines within the merge request, including the deployment process.                                                                                 |
| [SAST (Static Application Security Testing)](../../application_security/sast/index.md) **(ULTIMATE)**  | Analyze your source code for vulnerabilities                                                                                                                                                              |

## Authorization for merge requests

There are two main ways to have a merge request flow with GitLab:

1. Working with [protected branches](../protected_branches.md) in a single repository
1. Working with forks of an authoritative project

[Learn more about the authorization for merge requests.](authorization_for_merge_requests.md)

## Checkout merge requests locally

WIP (To be deleted before merge. Not deleted yet to speed up pipeline)
