# Working with merge requests

There are many ways to work with merge requests.

| Feature                                                                                         | Tier    | Description                                                                                                                                              |
|-------------------------------------------------------------------------------------------------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Bulk editing merge requests](../../project/bulk_editing.md)                                    |         |                                                                                                                                                          |
| [Cherry-pick changes](cherry_pick_changes.md)                                                   |         | Cherry-pick any commit in the UI by simply clicking the **Cherry-pick** button in a merged merge requests or a commit.                                   |
| [Commenting on any file line in merge requests](#commenting-on-any-file-line-in-merge-requests) |         |                                                                                                                                                          |
| [Fast-forward merge requests](fast_forward_merge.md)                                            |         | For a linear Git history and a way to accept merge requests without creating merge commits                                                               |
| [Find the merge request that introduced a change](versions.md)                                  |         | When viewing the commit details page, GitLab will link to the merge request(s) containing that commit.                                                   |
| [Live preview with Review Apps](#live-preview-with-review-apps)                                 |         |                                                                                                                                                          |
| [Merge requests versions](versions.md)                                                          |         | Select and compare the different versions of merge request diffs                                                                                         |
| [Merge when pipeline succeeds](merge_when_pipeline_succeeds.md)                                 |         | Set a merge request that looks ready to merge to merge automatically when CI pipeline succeeds.                                                          |
| [Perform a Review](../../discussions/index.md#merge-request-reviews-premium)                    | Premium | Start a review in order to create multiple comments on a diff and publish them once you're ready.                                                        |
| [Pipeline status in merge requests](#pipeline-status-in-merge-requests)                         |         |                                                                                                                                                          |
| [Post-merge pipeline status](#post-merge-pipeline-status)                                       |         |                                                                                                                                                          |
| [Resolve conflicts](resolve_conflicts.md)                                                       |         | GitLab can provide the option to resolve certain merge request conflicts in the GitLab UI.                                                               |
| [Resolve threads in merge requests reviews](../../discussions/index.md)                         |         | Keep track of the progress during a code review by resolving comments.                                                                                   |
| [Revert changes](revert_changes.md)                                                             |         | Revert changes from any commit from within a merge request.                                                                                              |
| [Semi-linear history merge requests](#semi-linear-history-merge-requests)                       |         |                                                                                                                                                          |
| [Suggest changes](../../discussions/index.md#suggest-changes)                                   |         | Add suggestions to change the content of merge requests directly into merge request threads, and easily apply them to the codebase directly from the UI. |
| [View group merge requests](#view-group-merge-requests)                                         |         |                                                                                                                                                          |
| [View project merge requests](#view-project-merge-requests)                                     |         |                                                                                                                                                          |
| [Authorization for merge requests](#authorization-for-merge-requests)                           |         |                                                                                                                                                          |

## View project merge requests

View all the merge requests within a project by navigating to **Project > Merge Requests**.

When you access your project's merge requests, GitLab will present them in a list,
and you can use the tabs available to quickly filter by open and closed. You can also [search and filter the results](../../search/index.md#issues-and-merge-requests-per-project).

![Project merge requests list view](img/project_merge_requests_list_view.png)

## View group merge requests

View merge requests in all projects in the group, including all projects of all descendant subgroups of the group. Navigate to **Group > Merge Requests** to view these merge requests. This view also has the open and closed merge requests tabs.

You can [search and filter the results](../../search/index.md#issues-and-merge-requests-per-group) from here.

![Group Issues list view](img/group_merge_requests_list_view.png)

## Semi-linear history merge requests

A merge commit is created for every merge, but the branch is only merged if
a fast-forward merge is possible. This ensures that if the merge request build
succeeded, the target branch build will also succeed after merging.

Navigate to a project's settings, select the **Merge commit with semi-linear history**
option under **Merge Requests: Merge method** and save your changes.

## Commenting on any file line in merge requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/13950) in GitLab 11.5.

GitLab provides a way of leaving comments in any part of the file being changed
in a Merge Request. To do so, click the **...** button in the gutter of the Merge Request diff UI to expand the diff lines and leave a comment, just as you would for a changed line.

![Comment on any diff file line](img/comment-on-any-diff-line.png)

## Live preview with Review Apps

If you configured [Review Apps](https://about.gitlab.com/product/review-apps/) for your project,
you can preview the changes submitted to a feature-branch through a merge request
in a per-branch basis. No need to checkout the branch, install and preview locally;
all your changes will be available to preview by anyone with the Review Apps link.

With GitLab's [Route Maps](../../../ci/review_apps/index.md#route-maps) set, the
merge request widget takes you directly to the pages changed, making it easier and
faster to preview proposed modifications.

[Read more about Review Apps](../../../ci/review_apps/index.md).

## Pipeline status in merge requests

If you've set up [GitLab CI/CD](../../../ci/README.md) in your project,
you will be able to see:

- Both pre and post-merge pipelines and the environment information if any.
- Which deployments are in progress.

If there's an [environment](../../../ci/environments.md) and the application is
successfully deployed to it, the deployed environment and the link to the
Review App will be shown as well.

### Post-merge pipeline status

When a merge request is merged, you can see the post-merge pipeline status of
the branch the merge request was merged into. For example, when a merge request
is merged into the master branch and then triggers a deployment to the staging
environment.

Deployments that are ongoing will be shown, as well as the deploying/deployed state
for environments. If it's the first time the branch is deployed, the link
will return a `404` error until done. During the deployment, the stop button will
be disabled. If the pipeline fails to deploy, the deployment info will be hidden.

![Merge request pipeline](img/merge_request_pipeline.png)

For more information, [read about pipelines](../../../ci/pipelines.md).

## Troubleshooting

Sometimes things don't go as expected in a merge request, here are some
troubleshooting steps.

### Merge request cannot retrieve the pipeline status

This can occur if Sidekiq doesn't pick up the changes fast enough.

#### Sidekiq

Sidekiq didn't process the CI state change fast enough. Please wait a few
seconds and the status will update automatically.

#### Bug

Merge Request pipeline statuses can't be retrieved when the following occurs:

1. A Merge Request is created
1. The Merge Request is closed
1. Changes are made in the project
1. The Merge Request is reopened

To enable the pipeline status to be properly retrieved, close and reopen the
Merge Request again.

## Tips

Here are some tips that will help you be more efficient with merge requests in
the command line.

> **Note:**
This section might move in its own document in the future.

### Checkout merge requests locally

A merge request contains all the history from a repository, plus the additional
commits added to the branch associated with the merge request. Here's a few
tricks to checkout a merge request locally.

Please note that you can checkout a merge request locally even if the source
project is a fork (even a private fork) of the target project.

#### Checkout locally by adding a Git alias

Add the following alias to your `~/.gitconfig`:

```
[alias]
    mr = !sh -c 'git fetch $1 merge-requests/$2/head:mr-$1-$2 && git checkout mr-$1-$2' -
```

Now you can check out a particular merge request from any repository and any
remote. For example, to check out the merge request with ID 5 as shown in GitLab
from the `origin` remote, do:

```
git mr origin 5
```

This will fetch the merge request into a local `mr-origin-5` branch and check
it out.

#### Checkout locally by modifying `.git/config` for a given repository

Locate the section for your GitLab remote in the `.git/config` file. It looks
like this:

```
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
```

You can open the file with:

```
git config -e
```

Now add the following line to the above section:

```
fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

In the end, it should look like this:

```
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
  fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

Now you can fetch all the merge requests:

```
git fetch origin

...
From https://gitlab.com/gitlab-org/gitlab-foss.git
 * [new ref]         refs/merge-requests/1/head -> origin/merge-requests/1
 * [new ref]         refs/merge-requests/2/head -> origin/merge-requests/2
...
```

And to check out a particular merge request:

```
git checkout origin/merge-requests/1
```

All the above can be done with the [`git-mr`](https://gitlab.com/glensc/git-mr) script.
