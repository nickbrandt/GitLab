# Development guide for Metrics Dashboards templates

This document explains how to develop Metrics Dashboards templates

## Place the template file in the relevant directory

All template files reside in the `lib/gitlab/metrics/templates` directory

## Criteria

All the templates must be named with the `*.metrics-dashboard.yml` suffix.

The file must follow the [custom dashboard syntax](../../../operations/metrics/dashboards/yaml.md).

### Make sure the new template can be selected in the UI

All the templates available in `lib/gitlab/metrics/templates` are selectable in the **New File** UI from the repository view as well from the **WebIDE** New File template selector.

![Metrics dashboard template selection](img/metrics_dashboard_template_selection_v13_3.png)
![Metrics dashboard template selection WebIDE](img/metrics_dashboard_template_selection_web_ide_v13_3.png)
