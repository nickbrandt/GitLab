# GitLab Go Proxy **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/27376) in [GitLab Premium](https://about.gitlab.com/pricing/) ??.??.

The GitLab Go Proxy implements the Go proxy protocol.

NOTE: **Note:**
GitLab does not (yet) display Go modules in the **Packages** section of a project.
Only the Go proxy protocol is supported at this time.

## Enabling the Go proxy

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled support for the Package Registry](../../../administration/packages/index.md). **(PREMIUM ONLY)**

After the Package Registry is enabled, it will be available for all new projects
by default. To enable it for existing projects, or if you want to disable it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages** section on the left sidebar.
