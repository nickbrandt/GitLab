---
description: "GitLab - Incident Management. GitLab offers solutions for handling incidents in your applications and services"
---

# Incident Management **(ULTIMATE)** (1)

<!--For pages on newly introduced features, add the following line. If only some aspects of the feature have been introduced, specify what parts of the feature.-->
> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/4925) in GitLab (Ultimate) 11.11.

## Overview

GitLab offers solutions for handling incidents in your applications and services from setting up an alert with Prometheus, to receiving a notification via a monitoring tool like Slack, and automatically setting up Zoom calls with your support team.

### Alerting

#### Prometheus Alerts
Prometheus alerts can be setup in both GitLab-managed Prometheus installs and self-managed Prometheus installs.

  Documentation for each method can be found here:
  - [GitLab-managed Prometheus](https://docs.gitlab.com/ee/user/project/integrations/prometheus.html#setting-up-alerts-for-prometheus-metrics-ultimate)
  - [Self-managed Prometheus](https://docs.gitlab.com/ee/user/project/integrations/prometheus.html#external-prometheus-instances)

#### Alert Endpoint

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).

#### Deduplication of alerts

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).

#### Recovery Alerts *

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).

### Configuring Incidents

#### Auto-creation

GitLab Issues can automatically be created as a result of an Alert notification. An Issue created this way will contain error information to help you further debug the error.

#### Issue templates

You can create your own Issue Templates than can be used within Incident Management.
To read how to create your own templates visit the [*Creating Issue Templates page*](../project/description_templates#creating-issue-templates).

To select your Issue Template for use within Incident Management, head to Project -> Settings -> Operations -> Incidents and select it under **Issue Template**.

### Embedded metrics

#### GitLab hosted metrics

You can embed metrics that are served by GitLab by following [these instructions](../project/integrations/prometheus.html#embedding-metric-charts-within-gitlab-flavored-markdown).
Including links to embedded metrics in issues templates

#### Grafana metrics

You can embed externally hosted Grafana metrics into GitLab issues by following [these instructions](user/project/integrations/prometheus.html#embedding-live-grafana-charts).

#### Metrics in issue templates

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).

### Slack integration

Slack slash commands allow you to control GitLab and view content right inside Slack, without having to leave it.

#### Setting it up

To setup Slack slash commands with GitLab, see [this guide](../project/integrations/slack_slash_commands).

#### Slash commands

Examples of Slash commands and how to use them can be [found here](../../ee/integration/slash_commands).

### Zoom in Issues

Documentation [coming soon](https://gitlab.com/gitlab-org/gitlab/issues/30832).
