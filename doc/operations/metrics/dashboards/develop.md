---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Developing templates for custom dashboards **(CORE)**

GitLab provides a template to make it easier for you to create templates for
[custom dashboards](index.md). Templates provide helpful guidance and
commented-out examples you can use.

## Create a new dashboard template

To create a new dashboard template to speed the development of more dashboards:

1. Navigate to the browser-based editor of your choice:

   - *To use the repository view,* navigate to **{doc-text}** **Repository > Files**.
   - *To use the [Web IDE](../../../user/project/web_ide/index.md),* click
     **Web IDE** when viewing your repository.
1. Create a template file that meets your needs, using the [custom dashboard syntax](yaml.md).
1. Save the template file in the `lib/gitlab/metrics/templates` directory,
   with a name matching the pattern `*.metrics-dashboard.yml`.
1. Reload the editor you used to create the new template and ensure the template
   is now available for use:

   - *In the repository view,* click **{plus}** **Add to tree** and select **New file**,
     then click **Select a template type** to see a list of available templates:
     ![Metrics dashboard template selection](img/metrics_dashboard_template_selection_v13_3.png)
   - *In the Web IDE,* click **Web IDE** when viewing your repository, click
     **{doc-new}** **New file**, then click **Choose a template** to see a list of
     available templates:
     ![Metrics dashboard template selection WebIDE](img/metrics_dashboard_template_selection_web_ide_v13_3.png)

## Template location and naming

For templates to be valid and available for use, they must:

1. Reside in the `lib/gitlab/metrics/templates` directory.
1. Be named with the `*.metrics-dashboard.yml` suffix.
1. Follow the [custom dashboard syntax](yaml.md).
