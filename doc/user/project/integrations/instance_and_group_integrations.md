---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Project integration management **(CORE ONLY)**

> [Introduced in](https://gitlab.com/groups/gitlab-org/-/epics/2137) GitLab 13.3.

Project integrations can be configured and enabled by project administrators. As a GitLab instance administrator, you can set default configuration parameters for a given integration that all projects can inherit and use.

You can update these default settings at any time, which will change the settings in use for all projects that are set to use instance-level defaults.

## Manage default settings for a project integration

1. Navigate to **Admin Area > Settings > Integrations**.
2. Select a project integration.
3. Enter configuration details and click **Save changes**.

For all projects that have a given integration set to use instance-level default settings, any changes you make to the instance defaults are immediately applied, changing their settings.

Projects with custom settings or without the integration enabled at all may choose to use the latest instance-level defaults at any time.
 
Note: If you set up an instance level integration for the first time, you will set up the same integration for all existing projects that do not have an integration of the same type set up. Projects with an existing integration of the same type are not changed.

## Use instance-level default settings for a project integration

1. Navigate to **Project > Settings > Integrations**.
1. Choose the integration you want to enable or update.
2. From the drop-down, select **Use instance-level settings**.
3. Ensure the toggle is set to **Enabled**.
4. Click **Save changes** 

![Screenshot of project-level integration with dropdown to use instance-level settings](./img/instance_level_dropdown.png)

## Use custom settings for a project integration

1. Navigate to **Project > Settings > Integrations**.
1. Choose the integration you want to enable or update.
1. From the drop-down, select **Use custom settings**.
1. Ensure the toggle is set to **Enabled** and enter all required settings.
1. Click **Save changes**.

## Caveats

Instance level integrations are just available for users of self-managed instances. We are currently working on enabling this logic on the group level as well, so that users of GitLab.com can also utilize this feature. [link tba]

Currently it is just possible to inherit the complete settings for an integration. Per-field inheritance is planned. [link tba]
