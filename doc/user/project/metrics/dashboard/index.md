---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Metrics dashboards

## Defining custom dashboards per project

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/59974) in GitLab 12.1.

By default, all projects include a GitLab-defined Prometheus dashboard, which
includes a few key metrics, but you can also define your own custom dashboards.

You may create a new file from scratch or duplicate a GitLab-defined Prometheus
dashboard.

NOTE: **Note:**
The metrics as defined below do not support alerts, unlike
[custom metrics](#adding-custom-metrics).

### Adding a new dashboard to your project

You can configure a custom dashboard by adding a new YAML file into your project's
`.gitlab/dashboards/` directory. In order for the dashboards to be displayed on
the project's **Operations > Metrics** page, the files must have a `.yml`
extension and should be present in the project's **default** branch.

For example:

1. Create `.gitlab/dashboards/prom_alerts.yml` under your repository's root
   directory with the following contents:

   ```yaml
   dashboard: 'Dashboard Title'
   panel_groups:
     - group: 'Group Title'
       panels:
       - type: area-chart
         title: "Chart Title"
         y_label: "Y-Axis"
         y_axis:
           format: number
           precision: 0
         metrics:
         - id: my_metric_id
           query_range: 'http_requests_total'
           label: "Instance: {{instance}}, method: {{method}}"
           unit: "count"
   ```

   The above sample dashboard would display a single area chart. Each file should
   define the layout of the dashboard and the Prometheus queries used to populate
   data.

1. Save the file, commit, and push to your repository. The file must be present in your **default** branch.
1. Navigate to your project's **Operations > Metrics** and choose the custom
   dashboard from the dropdown.

NOTE: **Note:**
Configuration files nested under subdirectories of `.gitlab/dashboards` are not
supported and will not be available in the UI.

## Duplicating a GitLab-defined dashboard

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/37238) in GitLab 12.7.
> - From [GitLab 12.8 onwards](https://gitlab.com/gitlab-org/gitlab/issues/39505), custom metrics are also duplicated when you duplicate a dashboard.

You can save a complete copy of a GitLab defined dashboard along with all custom metrics added to it.
Resulting `.yml` file can be customized and adapted to your project.
You can decide to save the dashboard `.yml` file in the project's **default** branch or in a
new branch.

1. Click **Duplicate dashboard** in the dashboard dropdown.

   NOTE: **Note:**
   You can duplicate only GitLab-defined dashboards.

1. Enter the file name and other information, such as the new commit's message, and click **Duplicate**.

If you select your **default** branch, the new dashboard becomes immediately available.
If you select another branch, this branch should be merged to your **default** branch first.

## Metrics dashboard visibility

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/201924) in GitLab 13.0.

You can set the visibility of the metrics dashboard to **Only Project Members**
or **Everyone With Access**. When set to **Everyone with Access**, the metrics
dashboard is visible to authenticated and non-authenticated users.

## Dashboard YAML properties

Dashboards have several components:

- Templating variables.
- Panel groups, which consist of panels.
- Panels, which support one or more metrics.

The following tables outline the details of expected properties.

### **Dashboard (top-level) properties**

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| `dashboard` | string | yes | Heading for the dashboard. Only one dashboard should be defined per file. |
| `panel_groups` | array | yes | The panel groups which should be on the dashboard. |
| `templating` | Hash | no | Top level key under which templating related options can be added. |

### **Templating (`templating`) properties**

| Property | Type | Required | Description |
| -------- | ---- | -------- | ----------- |
| `variables` | Hash | no | Variables can be defined here. |

Read the documentation on [templating](#templating-variables-for-metrics-dashboards).

### **Panel group (`panel_groups`) properties**

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| `group` | string | required | Heading for the panel group. |
| `priority` | number | optional, defaults to order in file | Order to appear on the dashboard. Higher number means higher priority, which will be higher on the page. Numbers do not need to be consecutive. |
| `panels` | array | required | The panels which should be in the panel group. |

### **Panel (`panels`) properties**

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------- |
| `type` | enum | no, defaults to `area-chart` | Specifies the chart type to use, can be: `area-chart`, `line-chart` or `anomaly-chart`. |
| `title` | string | yes | Heading for the panel. |
| `y_label` | string | no, but highly encouraged | Y-Axis label for the panel. |
| `y_axis` | string | no | Y-Axis configuration for the panel. |
| `max_value` | number | no | Denominator value used for calculating [percentile based results](#percentile-based-results) |
| `weight` | number | no, defaults to order in file | Order to appear within the grouping. Lower number means higher priority, which will be higher on the page. Numbers do not need to be consecutive. |
| `metrics` | array | yes | The metrics which should be displayed in the panel. Any number of metrics can be displayed when `type` is `area-chart` or `line-chart`, whereas only 3 can be displayed when `type` is `anomaly-chart`. |

### **Axis (`panels[].y_axis`) properties**

| Property    | Type   | Required                      | Description                                                          |
| ----------- | ------ | ----------------------------- | -------------------------------------------------------------------- |
| `name`      | string | no, but highly encouraged     | Y-Axis label for the panel. Replaces `y_label` if set.               |
| `format`    | string | no, defaults to `engineering` | Unit format used. See the [full list of units](../../integrations/prometheus_units.md). |
| `precision` | number | no, defaults to `2`           | Number of decimal places to display in the number.                                          |                        |

### **Metrics (`metrics`) properties**

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| `id` | string | no | Used for associating dashboard metrics with database records. Must be unique across dashboard configuration files. Required for [alerting](#setting-up-alerts-for-prometheus-metrics) (support not yet enabled, see [relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/27980)). |
| `unit` | string | yes | Defines the unit of the query's return data. |
| `label` | string | no, but highly encouraged | Defines the legend-label for the query. Should be unique within the panel's metrics. Can contain time series labels as interpolated variables. |
| `query` | string | yes if `query_range` is not defined | Defines the Prometheus query to be used to populate the chart/panel. If defined, the `query` endpoint of the [Prometheus API](https://prometheus.io/docs/prometheus/latest/querying/api/) will be utilized. |
| `query_range` | string | yes if `query` is not defined | Defines the Prometheus query to be used to populate the chart/panel. If defined, the `query_range` endpoint of the [Prometheus API](https://prometheus.io/docs/prometheus/latest/querying/api/) will be utilized. |
| `step` | number | no, value is calculated if not defined | Defines query resolution step width in float number of seconds. Metrics on the same panel should use the same `step` value. |

## Troubleshooting

When troubleshooting issues with a managed Prometheus app, it is often useful to
[view the Prometheus UI](../../../../development/prometheus.md#access-the-ui-of-a-prometheus-managed-application-in-kubernetes).

## "No data found" error on Metrics dashboard page

If the "No data found" screen continues to appear, it could be due to:

- No successful deployments have occurred to this environment.
- Prometheus does not have performance data for this environment, or the metrics
  are not labeled correctly. To test this, connect to the Prometheus server and
  [run a query](../../integrations/prometheus_library/kubernetes.md#metrics-supported), replacing `$CI_ENVIRONMENT_SLUG`
  with the name of your environment.
- You may need to re-add the GitLab predefined common metrics. This can be done by running the [import common metrics Rake task](../../../../administration/raketasks/maintenance.md#import-common-metrics).
