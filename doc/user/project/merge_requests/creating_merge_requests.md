# Creating merge requests

Merge requests are the primary method of making changes to files in a GitLab project.

| Feature                                                                                                             | Tier     | Description                                                                                                                                    |
|---------------------------------------------------------------------------------------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------|
| [Adding patches when creating a merge request via e-mail](#adding-patches-when-creating-a-merge-request-via-e-mail) |          |                                                                                                                                                |
| [Allow collaboration on merge requests across forks](#allow-collaboration-on-merge-requests-across-forks)           |          |                                                                                                                                                |
| [Create new merge requests by email](#create-new-merge-requests-by-email)                                           |          | Create new merge requests by sending an email to a user-specific email address.                                                                |
| [Deleting the source branch](#deleting-the-source-branch)                                                           |          | Select the "Delete source branch when merge request accepted" option and the source branch will be deleted when the merge request is merged.   |
| [Ignore whitespace changes in Merge Request diff view](#ignore-whitespace-changes-in-Merge-Request-diff-view)       |          |                                                                                                                                                |
| [Incrementally expand merge request diffs](#incrementally-expand-merge-request-diffs)                               |          |                                                                                                                                                |
| [Merge request approvals](merge_request_approvals.md)                                                               | Starter  | Set the number of necessary approvals and predefine a list of approvers that will need to approve every merge request in a project.            |
| [Merge Request Dependencies](merge_request_dependencies.md)                                                         | Premium  | Specify that a merge request depends on other MRs.                                                                                             |
| [Merge request diff file navigation](#merge-request-diff-file-navigation)                                           |          |                                                                                                                                                |
| [Merge Requests for Confidential Issues](../issues/confidential_issues.md#merge-requests-for-confidential-issues)   |          | Create merge requests to resolve confidential issues for preventing leakage or early release of sensitive data through regular merge requests. |
| [Multiple assignees](#multiple-assignees-starter)                                                                   | Starter  | Have multiple assignees for merge requests to indicate everyone that is reviewing or accountable for it.                                       |
| [Security reports](../../application_security/index.md)                                                             | Ultimate | GitLab can scan and report any vulnerabilities found in your project.                                                                          |
| [Squash and merge](#squash-and-merge)                                                                               |          | Squash all changes present in a merge request into a single commit when merging, to allow for a neater commit history.                         |
| [Work In Progress merge requests](#work-in-progress-merge-requests)                                                 |          |                                                                                                                                                |
| [Git push options](../push_options.md)                                                                              |          | Use Git push options to create or update merge requests when pushing changes to GitLab with Git, without needing to use the GitLab interface.  |
| [View changes between file versions](#view-changes-between-file-versions)                                           |          |                                                                                                                                                |

## Deleting the source branch

When creating a merge request, select the "Delete source branch when merge
request accepted" option and the source branch will be deleted when the merge
request is merged. To make this option enabled by default for all new merge
requests, enable it in the [project's settings](../settings/index.md#merge-request-settings).


This option is also visible in an existing merge request next to the merge
request button and can be selected/deselected before merging. It's only visible
to users with [Maintainer permissions](../../permissions.md) in the source project.

If the user viewing the merge request does not have the correct permissions to
delete the source branch and the source branch is set for deletion, the merge
request widget will show the "Deletes source branch" text.

![Delete source branch status](img/remove_source_branch_status.png)

## Allow collaboration on merge requests across forks

When a user opens a merge request from a fork, they are given the option to allow
upstream maintainers to collaborate with them on the source branch. This allows
the maintainers of the upstream project to make small fixes or rebase branches
before merging, reducing the back and forth of accepting community contributions.

[Learn more about allowing upstream members to push to forks.](allow_collaboration.md)

## View changes between file versions

The **Changes** tab of a merge request shows the changes to files between branches or
commits. This view of changes to a file is also known as a **diff**. By default, the diff view
compares the file in the merge request branch and the file in the target branch.

The diff view includes the following:

- The file's name and path.
- The number of lines added and deleted.
- Buttons for the following options:
  - Toggle comments for this file; useful for inline reviews.
  - Edit the file in the merge request's branch.
  - Show full file, in case you want to look at the changes in context with the rest of the file.
  - View file at the current commit.
  - Preview the changes with [Review Apps](../../../ci/review_apps/index.md).
- The changed lines, with the specific changes highlighted.

![Example screenshot of a source code diff](img/merge_request_diff_v12_2.png)

## Squash and merge

GitLab allows you to squash all changes present in a merge request into a single
commit when merging, to allow for a neater commit history.

[Learn more about squash and merge.](squash_and_merge.md)

## Multiple assignees **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/2004)
in [GitLab Starter 11.11](https://about.gitlab.com/pricing/).

Multiple people often review merge requests at the same time. GitLab allows you to have multiple assignees for merge requests to indicate everyone that is reviewing or accountable for it.

![multiple assignees for merge requests sidebar](img/multiple_assignees_for_merge_requests_sidebar.png)

To assign multiple assignees to a merge request:

1. From a merge request, expand the right sidebar and locate the **Assignees** section.
1. Click on **Edit** and from the dropdown menu, select as many users as you want
   to assign the merge request to.

Similarly, assignees are removed by deselecting them from the same dropdown menu.

It's also possible to manage multiple assignees:

- When creating a merge request.
- Using [quick actions](../quick_actions.md#quick-actions-for-issues-merge-requests-and-epics).

## Create new merge requests by email

_This feature needs [incoming email](../../../administration/incoming_email.md)
to be configured by a GitLab administrator to be available for CE/EE users, and
it's available on GitLab.com._

You can create a new merge request by sending an email to a user-specific email
address. The address can be obtained on the merge requests page by clicking on
a **Email a new merge request to this project** button.  The subject will be
used as the source branch name for the new merge request and the target branch
will be the default branch for the project. The message body (if not empty)
will be used as the merge request description. You need
["Reply by email"](../../../administration/reply_by_email.md) enabled to use
this feature. If it's not enabled to your instance, you may ask your GitLab
administrator to do so.

This is a private email address, generated just for you. **Keep it to yourself**
as anyone who gets ahold of it can create issues or merge requests as if they were you.
You can add this address to your contact list for easy access.

![Create new merge requests by email](img/create_from_email.png)

_In GitLab 11.7, we updated the format of the generated email address.
However the older format is still supported, allowing existing aliases
or contacts to continue working._

### Adding patches when creating a merge request via e-mail

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22723) in GitLab 11.5.

You can add commits to the merge request being created by adding
patches as attachments to the email. All attachments with a filename
ending in `.patch` will be considered patches and they will be processed
ordered by name.

The combined size of the patches can be 2MB.

If the source branch from the subject does not exist, it will be
created from the repository's HEAD or the specified target branch to
apply the patches. The target branch can be specified using the
[`/target_branch` quick action](../quick_actions.md). If the source
branch already exists, the patches will be applied on top of it.

## Work In Progress merge requests

To prevent merge requests from accidentally being accepted before they're
completely ready, GitLab blocks the "Accept" button for merge requests that
have been marked as a **Work In Progress**.

[Learn more about setting a merge request as "Work In Progress".](work_in_progress_merge_requests.md)

## Merge request diff file navigation

When reviewing changes in the **Changes** tab the diff can be navigated using
the file tree or file list. As you scroll through large diffs with many
changes, you can quickly jump to any changed file using the file tree or file
list.

![Merge request diff file navigation](img/merge_request_diff_file_navigation.png)

### Incrementally expand merge request diffs

By default, the diff shows only the parts of a file which are changed.
To view more unchanged lines above or below a change click on the
**Expand up** or **Expand down** icons. You can also click on **Show all lines**
to expand the entire file.

![Incrementally expand merge request diffs](img/incrementally_expand_merge_request_diffs_v12_2.png)

## Ignore whitespace changes in Merge Request diff view

If you click the **Hide whitespace changes** button, you can see the diff
without whitespace changes (if there are any). This is also working when on a
specific commit page.

![MR diff](img/merge_request_diff.png)

>**Tip:**
You can append `?w=1` while on the diffs page of a merge request to ignore any
whitespace changes.
