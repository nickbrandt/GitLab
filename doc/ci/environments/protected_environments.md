---
stage: Release
group: Release Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: concepts, howto
---

# Protected Environments **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6303) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.3.

## Overview

[Environments](../environments/index.md) can be used for different reasons:

- Some of them are just for testing.
- Others are for production.

Since deploy jobs can be raised by different users with different roles, it is important that
specific environments are "protected" to prevent unauthorized people from affecting them.

By default, a protected environment does one thing: it ensures that only people
with the right privileges can deploy to it, thus keeping it safe.

NOTE: **Note:**
A GitLab admin is always allowed to use environments, even if they are protected.

To protect, update, or unprotect an environment, you need to have at least
[Maintainer permissions](../../user/permissions.md).

## Protecting environments

To protect an environment:

1. Navigate to your project's **Settings > CI/CD**.
1. Expand the **Protected Environments** section.
1. From the **Environment** dropdown menu, select the environment you want to protect.
1. In the **Allowed to Deploy** dropdown menu, select the role, users, or groups you
   want to give deploy access to. Keep in mind that:
   - There are two roles to choose from:
     - **Maintainers**: will allow access to all maintainers in the project.
     - **Developers**: will allow access to all maintainers and all developers in the project.
   - You can only select groups that are already associated with the project.
   - Only users that have at least Developer permission level will appear in
     the **Allowed to Deploy** dropdown menu.
1. Click the **Protect** button.

The protected environment will now appear in the list of protected environments.

## Access via Group

A user may be granted access to protected environments as part of group membership.
For Reporters, this is the only way they may be granted access.

## Access to deployment branch

When a Developer is granted access to a protected environment, either as an individual
contributor, via Role or via a group _and_ they also have access to either push or merge
to the branch that production is deployed, they have the following privileges:

- stop environment
- destroy environment
- create an environment terminal

## Deployment-only access

When a user has access granted to a protected environment, and does not have access to push
or merge to the branch, they are granted access _only_ to deploy the environment.

This is the only possible access level for Reporters.

## Modifying and unprotecting environments

Maintainers can:

- Update existing protected environments at any time by changing the access in the
  **Allowed to Deploy** dropdown menu.
- Unprotect a protected environment by clicking the **Unprotect** button for that environment.

Note that once an environment is unprotected, all access entries are deleted and would need to
be re-entered should the environment be re-protected.

For more information, see [Deployment safety](deployment_safety.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
