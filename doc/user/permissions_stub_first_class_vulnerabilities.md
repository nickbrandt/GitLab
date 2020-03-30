---
description: 'Understand and explore the user permission levels in GitLab, and what features each of them grants you access to.'
---

# Permissions

Users have different abilities depending on the access level they have in a
particular group or project: 

- GitLab [administrators](../administration/index.md) receive all permissions.
- If a user is both in a group's project and the project itself, the highest
  permission level is used. For more information, see
  [Project member permissions](#project-members-permissions).
- The Guest role is not enforced on public and internal projects. All users can
  create issues, leave comments, and clone or download the project code.
- When a member leaves a team's project, all the assigned
  [Issues](project/issues/index.md) and [Merge Requests](project/merge_requests/index.md)
  will be unassigned automatically.

To add or import a user, you can follow the
[project members documentation](project/members/index.md).

For information on eligible approvers for Merge Requests, see
[Eligible approvers](project/merge_requests/merge_request_approvals.md#eligible-approvers).

To learn more about the principles behind permissions, see the
[GitLab product handbook on permissions](https://about.gitlab.com/handbook/product/#permissions-in-gitlab).

## Instance-wide user permissions

By default, users can create top-level groups and change their
usernames. A GitLab administrator can configure the GitLab instance to
[modify this behavior](../administration/user_settings.md).

## Project members permissions

NOTE: **Note:**
In GitLab 11.0, the Master role was renamed to Maintainer.

While Maintainer is the highest project-level role, some actions can only be performed by a personal namespace or group owner. The following table depicts the various user permission levels in a project:

| Action                                            | Guest   | Reporter   | Developer   |Maintainer| Owner  |
|---------------------------------------------------|---------|------------|-------------|----------|--------|
| Download project                                  | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| Leave comments                                    | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View Insights charts **(ULTIMATE)**               | ✓       | ✓          | ✓           | ✓        | ✓      |
| View approved/blacklisted licenses **(ULTIMATE)** | ✓       | ✓          | ✓           | ✓        | ✓      |
| View License Compliance reports **(ULTIMATE)**    | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View Security reports **(ULTIMATE)**              | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| View Dependency list **(ULTIMATE)**               | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View licenses in Dependency list **(ULTIMATE)**   | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View [Design Management](project/issues/design_management.md) pages **(PREMIUM)** | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View project code                                 | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| Pull project code                                 | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View GitLab Pages protected by [access control](project/pages/introduction.md#gitlab-pages-access-control-core) | ✓       | ✓          | ✓           | ✓        | ✓      |
| View wiki pages                                   | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| See a list of jobs                                | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| See a job log                                     | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| Download and browse job artifacts                 | ✓ (*3*) | ✓          | ✓           | ✓        | ✓      |
| Create new issue                                  | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| See related issues                                | ✓       | ✓          | ✓           | ✓        | ✓      |
| Create confidential issue                         | ✓ (*1*) | ✓          | ✓           | ✓        | ✓      |
| View confidential issues                          | (*2*)   | ✓          | ✓           | ✓        | ✓      |
| Assign issues                                     |         | ✓          | ✓           | ✓        | ✓      |
| Label issues                                      |         | ✓          | ✓           | ✓        | ✓      |
| Lock issue threads                                |         | ✓          | ✓           | ✓        | ✓      |
| Manage issue tracker                              |         | ✓          | ✓           | ✓        | ✓      |
| Manage related issues **(STARTER)**               |         | ✓          | ✓           | ✓        | ✓      |
| Manage labels                                     |         | ✓          | ✓           | ✓        | ✓      |
| Create code snippets                              |         | ✓          | ✓           | ✓        | ✓      |
| See a commit status                               |         | ✓          | ✓           | ✓        | ✓      |
| See a container registry                          |         | ✓          | ✓           | ✓        | ✓      |
| See environments                                  |         | ✓          | ✓           | ✓        | ✓      |
| See a list of merge requests                      |         | ✓          | ✓           | ✓        | ✓      |
| View project statistics                           |         | ✓          | ✓           | ✓        | ✓      |
| View Error Tracking list                          |         | ✓          | ✓           | ✓        | ✓      |
| Pull from [Conan repository](packages/conan_repository/index.md), [Maven repository](packages/maven_repository/index.md), or [NPM registry](packages/npm_registry/index.md) **(PREMIUM)** |         | ✓          | ✓           | ✓        | ✓      |
| Publish to [Conan repository](packages/conan_repository/index.md), [Maven repository](packages/maven_repository/index.md), or [NPM registry](packages/npm_registry/index.md) **(PREMIUM)** |         |            | ✓           | ✓        | ✓      |
| Upload [Design Management](project/issues/design_management.md) files **(PREMIUM)** |         |            | ✓           | ✓        | ✓      |
| Create new branches                               |         |            | ✓           | ✓        | ✓      |
| Push to non-protected branches                    |         |            | ✓           | ✓        | ✓      |
| Force push to non-protected branches              |         |            | ✓           | ✓        | ✓      |
| Remove non-protected branches                     |         |            | ✓           | ✓        | ✓      |
| Create new merge request                          |         |            | ✓           | ✓        | ✓      |
| Assign merge requests                             |         |            | ✓           | ✓        | ✓      |
| Label merge requests                              |         |            | ✓           | ✓        | ✓      |
| Lock merge request threads                        |         |            | ✓           | ✓        | ✓      |
| Manage/Accept merge requests                      |         |            | ✓           | ✓        | ✓      |
| Create new environments                           |         |            | ✓           | ✓        | ✓      |
| Stop environments                                 |         |            | ✓           | ✓        | ✓      |
| Add tags                                          |         |            | ✓           | ✓        | ✓      |
| Cancel and retry jobs                             |         |            | ✓           | ✓        | ✓      |
| Create or update commit status                    |         |            | ✓           | ✓        | ✓      |
| Update a container registry                       |         |            | ✓           | ✓        | ✓      |
| Remove a container registry image                 |         |            | ✓           | ✓        | ✓      |
| Create/edit/delete project milestones             |         |            | ✓           | ✓        | ✓      |
| Use security dashboard **(ULTIMATE)**             |         |            | ✓           | ✓        | ✓      |
| View vulnerability findings in Dependency list **(ULTIMATE)** |    |     | ✓           | ✓        | ✓      |
| Create issue from vulnerability finding **(ULTIMATE)** |    |            | ✓           | ✓        | ✓      |
| Dismiss vulnerability finding **(ULTIMATE)**      |         |            | ✓           | ✓        | ✓      |
| View vulnerability **(ULTIMATE)**                 |         |            | ✓           | ✓        | ✓      |
| Create vulnerability from vulnerability finding **(ULTIMATE)** |   |     | ✓           | ✓        | ✓      |
| Resolve vulnerability **(ULTIMATE)**              |         |            | ✓           | ✓        | ✓      |
| Dismiss vulnerability **(ULTIMATE)**              |         |            | ✓           | ✓        | ✓      |
| Apply code change suggestions                     |         |            | ✓           | ✓        | ✓      |
| Create and edit wiki pages                        |         |            | ✓           | ✓        | ✓      |
| Rewrite/remove Git tags                           |         |            | ✓           | ✓        | ✓      |
| Use environment terminals                         |         |            |             | ✓        | ✓      |
| Run Web IDE's Interactive Web Terminals **(ULTIMATE ONLY)** |      |     |             | ✓        | ✓      |
| Add new team members                              |         |            |             | ✓        | ✓      |
| Enable/disable branch protection                  |         |            |             | ✓        | ✓      |
| Push to protected branches                        |         |            |             | ✓        | ✓      |
| Turn on/off protected branch push for devs        |         |            |             | ✓        | ✓      |
| Enable/disable tag protections                    |         |            |             | ✓        | ✓      |
| Edit project                                      |         |            |             | ✓        | ✓      |
| Add deploy keys to project                        |         |            |             | ✓        | ✓      |
| Configure project hooks                           |         |            |             | ✓        | ✓      |
| Manage Runners                                    |         |            |             | ✓        | ✓      |
| Manage job triggers                               |         |            |             | ✓        | ✓      |
| Manage variables                                  |         |            |             | ✓        | ✓      |
| Manage GitLab Pages                               |         |            |             | ✓        | ✓      |
| Manage GitLab Pages domains and certificates      |         |            |             | ✓        | ✓      |
| Remove GitLab Pages                               |         |            |             | ✓        | ✓      |
| Manage clusters                                   |         |            |             | ✓        | ✓      |
| Manage license policy **(ULTIMATE)**              |         |            |             | ✓        | ✓      |
| Edit comments (posted by any user)                |         |            |             | ✓        | ✓      |
| Manage Error Tracking                             |         |            |             | ✓        | ✓      |
| Delete wiki pages                                 |         |            |             | ✓        | ✓      |
| View project Audit Events                         |         |            |             | ✓        | ✓      |
| Manage [push rules](../push_rules/push_rules.md)  |         |            |             | ✓        | ✓      |
| Switch visibility level                           |         |            |             |          | ✓      |
| Transfer project to another namespace             |         |            |             |          | ✓      |
| Remove project                                    |         |            |             |          | ✓      |
| Delete issues                                     |         |            |             |          | ✓      |
| Disable notification emails                       |         |            |             |          | ✓      |
| Force push to protected branches (*4*)            |         |            |             |          |        |
| Remove protected branches (*4*)                   |         |            |             |          |        |

- (*1*): Guest users can perform this action on public and internal projects, but not private projects.
- (*2*): Guest users can only view the confidential issues they created.
- (*3*): If **Public pipelines** is enabled in **{settings}** **Project Settings > CI/CD**.
- (*4*): Not allowed for Guest, Reporter, Developer, Maintainer, or Owner. See [Protected Branches](project/protected_branches.md).

## Project features permissions

### Wikis and issues

Project features like wikis and issues can be hidden from users depending on
the visibility level you select in project settings:

- **Disabled**: disabled for everyone.
- **Only team members**: only team members can view, even if your project is public or internal.
- **Everyone with access**: everyone can view, depending on your project visibility level.
- **Everyone**: enabled for everyone (only available for [GitLab Pages](project/pages.md)).

### Protected branches

You can apply additional restrictions on a per-branch basis using [protected branches](project/protected_branches.md), and customize permissions to allow or prevent
Maintainers or Developers from pushing to a protected branch. 

For more information, see
[Allowed to Merge and Allowed to Push settings](project/protected_branches.md#using-the-allowed-to-merge-and-allowed-to-push-settings).

### Cycle Analytics permissions

Find the current permissions on the Cycle Analytics dashboard on
the [documentation on Cycle Analytics permissions](analytics/cycle_analytics.md#permissions).

### Issue Board permissions

Developers and users with higher permission levels can use all features of the
Issue Board, including creating lists, deleting lists, and dragging-and-dropping
issues. See the [Issue Boards permissions documentation](project/issue_board.md#permissions)
to learn more.

### File Locking permissions **(PREMIUM)**

Only the user that locks a file or directory can edit and push their changes back to the repository where the locked objects are located.

For more information, see the
[permissions for File Locking](project/file_lock.md#permissions-on-file-locking) documentation.

### Confidential Issues permissions

Confidential issues can be accessed by users with
[Reporter and higher](permissions.md#project-members-permissions) permission levels.
Guest users that create a confidential issue can view their own issues. To learn more,
see the documentation on [permissions and access to confidential issues](project/issues/confidential_issues.md#permissions-and-access-to-confidential-issues).

### Releases permissions

[Project Releases](project/releases/index.md) can be read by project
members with Reporter, Developer, Maintainer, and Owner permissions.
Guest users can access Release pages for downloading assets but
are not allowed to download the source code nor see repository
information such as tags and commits.

Releases can be created, updated, or deleted via [Releases APIs](../api/releases/index.md)
by project Developers, Maintainers, and Owners.

## Group members permissions

NOTE: **Note:**
In GitLab 11.0, the Master role was renamed to Maintainer.

Any user can remove themselves from a group, unless they are the last Owner of
the group. The following table depicts the various user permission levels in a
group.

| Action                                                 | Guest | Reporter | Developer | Maintainer | Owner |
|--------------------------------------------------------|-------|----------|-----------|------------|-------|
| Browse group                                           | ✓     | ✓        | ✓         | ✓          | ✓     |
| View Insights charts **(ULTIMATE)**                    | ✓     | ✓        | ✓         | ✓          | ✓     |
| View group epic **(ULTIMATE)**                         | ✓     | ✓        | ✓         | ✓          | ✓     |
| Create/edit group epic **(ULTIMATE)**                  |       | ✓        | ✓         | ✓          | ✓     |
| Manage group labels                                    |       | ✓        | ✓         | ✓          | ✓     |
| Create project in group                                |       |          | ✓ (3)     | ✓ (3)      | ✓ (3) |
| Create/edit/delete group milestones                    |       |          | ✓         | ✓          | ✓     |
| Enable/disable a dependency proxy **(PREMIUM)**        |       |          | ✓         | ✓          | ✓     |
| Use security dashboard **(ULTIMATE)**                  |       |          | ✓         | ✓          | ✓     |
| Create subgroup                                        |       |          |           | ✓ (1)      | ✓     |
| Edit group                                             |       |          |           |            | ✓     |
| Manage group members                                   |       |          |           |            | ✓     |
| Remove group                                           |       |          |           |            | ✓     |
| Delete group epic **(ULTIMATE)**                       |       |          |           |            | ✓     |
| Edit epic comments (posted by any user) **(ULTIMATE)** |       |          |           | ✓ (2)      | ✓ (2) |
| View group Audit Events                                |       |          |           |            | ✓     |
| Disable notification emails                            |       |          |           |            | ✓     |
| View/manage group-level Kubernetes cluster             |       |          |           | ✓          | ✓     |

- (1): Groups can be set to [allow either Owners or Owners and
  Maintainers to create subgroups](group/subgroups/index.md#creating-a-subgroup)
- (2): Introduced in GitLab 12.2.
- (3): Default project creation role can be changed at:
  - The [instance level](admin_area/settings/visibility_and_access_controls.md#default-project-creation-protection).
  - The [group level](group/index.md#default-project-creation-level).

### Subgroup permissions

When you add a member to a subgroup, the user inherits the membership and
permission level from the parent group. This model allows users access to
nested groups if they have membership in one of its parents.

To learn more, read through the documentation on
[subgroups memberships](group/subgroups/index.md#membership).

## External users **(CORE ONLY)**

To grant a user has access only to some, but not all, internal or private
projects, you can create **External Users**. This feature can be useful
for limiting which private projects a user can access, such as an external
contractor who should only have access to a specific project.

External users have the following permissions:

- They cannot create groups or projects.
- They can only access projects to which they are explicitly granted access.
  All other internal or private projects are hidden from them.

To grant access to an external user, add the user as a member to a project
or group. The external user receives a role in the project or group, with
all the abilities described in the [permissions table](#project-members-permissions).
For example, an external user added to a private project will not have access
to the code; the external user would need access at the Reporter level or above
to have code access. 

You should always consider the
[project's visibility and permissions settings](project/settings/index.md#sharing-and-permissions),
as well as the permission level of the user.

NOTE: **Note:**
External users still count towards a license seat.

To mark a user as an external user, an administrator must perform one of the following actions:

- Mark the user as external [through the API](../api/users.md#user-modification).
- Navigate to the **Admin area > Overview > Users** to create a new user
  or edit an existing user. There, you will find the option to flag the user as
  external.

### Setting new users to external

New users are not set as external users by default. An administrator can change
this behavior at the **Admin Area > Settings > General > Account and limit** page.

After changing the default behavior of creating new users as external, you can
optionally define a set of internal users in the **Internal users** field, by
providing a regex pattern based on email address. New users with an email address
matching the regex pattern will be marked as internal by default.

The regex pattern format is Ruby, but it needs to be convertible to JavaScript,
and the ignore case flag will be set (`/regex pattern/i`). Here are some examples:

- Use `\.internal@domain\.com$` to mark email addresses ending with
  `.internal@domain.com` as internal.
- Use `^(?:(?!\.ext@domain\.com).)*$\r?` to mark users with email addresses
  NOT including `.ext@domain.com` as internal.

CAUTION: **Warning:**
Be aware that this regex could lead to a
[regular expression denial of service (ReDoS) attack](https://en.wikipedia.org/wiki/ReDoS).

## Free Guest users **(ULTIMATE)**

When a user is given Guest permissions on a project, group, or both, and holds no
higher permission level on any other project or group on the GitLab instance,
the user is considered a guest user by GitLab and will not consume a license seat.
There is no other specific "guest" designation for newly created users.

If the user is assigned a higher role on any projects or groups, the user will
take a license seat. If a user creates a project, the user becomes a Maintainer
on the project, resulting in the use of a license seat. Also, note that if your
project is internal or private, Guest users will have all the abilities that are
mentioned in the [permissions table above](#project-members-permissions) (they
will not be able to browse the project's repository for example).

TIP: **Tip:**
Administrators can prevent a guest user from creating projects by editing the
user's profile to mark the user as [external](#external-users-core-only).
Be aware that even if an external user already has Reporter or higher permissions
in any project or group, they will **not** be counted as a free guest user.

## Auditor users **(PREMIUM ONLY)**

>[Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/998) in [GitLab Premium](https://about.gitlab.com/pricing/) 8.17.

Auditor users are given read-only access to all projects, groups, and other
resources on the GitLab instance.

An Auditor user can access all projects and groups of a GitLab instance
with the permissions described on the [auditor users permissions](../administration/auditor_users.md#permissions-and-restrictions-of-an-auditor-user)
documentation page.

[Read more about Auditor users.](../administration/auditor_users.md)

## Project features

Project features like wikis and issues can be hidden from users depending on
the visibility level you select in project settings:

   - **Disabled**: disabled for everyone.
   - **Only team members**: only team members can view, even if your project is public or internal.
   - **Everyone with access**: everyone can view, depending on your project visibility level.
   - **Everyone**: enabled for everyone (only available for [GitLab Pages](project/pages.md)).

## GitLab CI/CD permissions

NOTE: **Note:**
In GitLab 11.0, the Master role was renamed to Maintainer.

GitLab CI/CD permissions rely on the role the user has in GitLab. The following
permission levels are available:

- Admin
- Maintainer
- Developer
- Guest (Reporter)

The admin user can perform any action on GitLab CI/CD in scope of the GitLab
instance and project. In addition, all admins can use the admin interface under
`/admin/runners`.

| Action                                | Guest, Reporter | Developer   |Maintainer| Admin  |
|---------------------------------------|-----------------|-------------|----------|--------|
| See commits and jobs                  | ✓               | ✓           | ✓        | ✓      |
| Retry or cancel job                   |                 | ✓           | ✓        | ✓      |
| Erase job artifacts and trace         |                 | ✓ (*1*)     | ✓        | ✓      |
| Remove project                        |                 |             | ✓        | ✓      |
| Create project                        |                 |             | ✓        | ✓      |
| Change project configuration          |                 |             | ✓        | ✓      |
| Add specific runners                  |                 |             | ✓        | ✓      |
| Add shared runners                    |                 |             |          | ✓      |
| See events in the system              |                 |             |          | ✓      |
| Admin interface                       |                 |             |          | ✓      |

- *1*: Only if the job was triggered by the user

### Job permissions

NOTE: **Note:**
In GitLab 11.0, the Master role was renamed to Maintainer.

>**Note:**
GitLab 8.12 has a completely redesigned job permissions system.
Read all about the [new model and its implications](project/new_ci_build_permissions_model.md).

This table shows granted privileges for jobs triggered by specific types of
users:

| Action                                      | Guest, Reporter | Developer   |Maintainer| Admin   |
|---------------------------------------------|-----------------|-------------|----------|---------|
| Run CI job                                  |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from current project   |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from public projects   |                 | ✓           | ✓        | ✓       |
| Clone source and LFS from internal projects |                 | ✓ (*1*)     | ✓  (*1*) | ✓       |
| Clone source and LFS from private projects  |                 | ✓ (*2*)     | ✓  (*2*) | ✓ (*2*) |
| Pull container images from current project  |                 | ✓           | ✓        | ✓       |
| Pull container images from public projects  |                 | ✓           | ✓        | ✓       |
| Pull container images from internal projects|                 | ✓ (*1*)     | ✓  (*1*) | ✓       |
| Pull container images from private projects |                 | ✓ (*2*)     | ✓  (*2*) | ✓ (*2*) |
| Push container images to current project    |                 | ✓           | ✓        | ✓       |
| Push container images to other projects     |                 |             |          |         |
| Push source and LFS                         |                 |             |          |         |

- *1*: Only if the user is not an external one
- *2*: Only if the user is a member of the project

### New CI job permissions model

GitLab 8.12 has a completely redesigned job permissions system. To learn more,
read through the documentation on the [new CI/CD permissions model](project/new_ci_build_permissions_model.md#new-ci-job-permissions-model).

## Running pipelines on protected branches

The permission to merge or push to protected branches defines whether a user can
run CI/CD pipelines and execute actions on jobs that are related to those branches.

See [Security on protected branches](../ci/pipelines.md#security-on-protected-branches)
for details about the pipelines security model.

## LDAP users permissions

Since GitLab 8.15, admin users can manually override LDAP user permissions.
Read through the documentation on [LDAP users permissions](../administration/auth/how_to_configure_ldap_gitlab_ee/index.html) to learn more.

## Project aliases

Project aliases can only be read, created and deleted by a GitLab administrator.
Read through the documentation on [Project aliases](../user/project/index.md#project-aliases-premium-only) to learn more.
