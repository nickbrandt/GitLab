---
description: "GitLab - Incident Management. GitLab offers solutions for handling incidents in your applications and services"
---

# Incident Management **(ULTIMATE)**

<!--For pages on newly introduced features, add the following line. If only some aspects of the feature have been introduced, specify what parts of the feature.-->
> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/4925) in GitLab (Ultimate) 11.11.

## Overview

GitLab offers solutions for handling incidents in your applications and services from setting up an alert with Prometheus, to receiving a notification via a monitoring tool like Slack, and automatically setting up Zoom calls with your support team.

### Alerting

You can let GitLab know of alerts that may be triggering in your applications and services. GitLab can react to these by automatically creating Issues, and alerting developers via Email.

#### Prometheus Alerts

Prometheus alerts can be setup in both GitLab-managed Prometheus installs and self-managed Prometheus installs.

Documentation for each method can be found here:

- [GitLab-managed Prometheus](../project/integrations/prometheus.html#setting-up-alerts-for-prometheus-metrics-ultimate)
- [Self-managed Prometheus](../project/integrations/prometheus.html#external-prometheus-instances)

#### Alert Endpoint

This generic alert endpoint allows you to send GitLab alert notifications via a Webhook.

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).

#### Recovery Alerts

GitLab can automatically close Issues that have been automatically created when we receive notification that the alert is resolved.

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).

### Configuring Incidents

Incident Management features can be easily enabled & disabled via the Project settings page. Head to Project -> Settings -> Operations -> Incidents.

#### Auto-creation

GitLab Issues can automatically be created as a result of an Alert notification. An Issue created this way will contain error information to help you further debug the error.

#### Issue templates

You can create your own Issue Templates than can be used within Incident Management.
To read how to create your own templates visit the [*Creating Issue Templates page*](../project/description_templates.md#creating-issue-templates).

To select your Issue Template for use within Incident Management, head to Project -> Settings -> Operations -> Incidents and select it under **Issue Template**.

### Embedded metrics

Metrics can be embedded anywhere where GitLab Markdown is used. This issues issues, merge requests and comments.

#### GitLab hosted metrics

You can embed metrics that are served by GitLab by following [these instructions](../project/integrations/prometheus.md#embedding-metric-charts-within-gitlab-flavored-markdown).
Including links to embedded metrics in issues templates

#### Grafana metrics

You can embed externally hosted Grafana metrics into GitLab issues by following [these instructions](../project/integrations/prometheus.md#embedding-live-grafana-charts).

#### Metrics in issue templates

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).

### Slack integration

Slack slash commands allow you to control GitLab and view content right inside Slack, without having to leave it.

#### Setting it up

To setup Slack slash commands with GitLab, see [this guide](../project/integrations/slack_slash_commands.md).

#### Slash commands

Examples of Slash commands and how to use them can be [found here](../../integration/slash_commands.md).

### Zoom in Issues

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).
