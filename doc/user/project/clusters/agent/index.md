---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Kubernetes agent

GitLab Kubernetes Agent is an active in-cluster component for solving numerous GitLab <-> Kubernetes integration tasks.

NOTE: **Note:**
This feature is a work in progress.

We encourage you to read about:
 1. [The Architecture](architecture.md)
 1. [Identity and Authentication model](identity_and_auth.md)
 1. [Configuring the Agent](configuration_repository.md)
 1. [Enabling GitOps deployments](gitops.md)

## Use cases and ideas

Below are some ideas that can be built using the agent.

- **Real-time and resilient web hooks.** Polling Git repositories scales poorly and so webhooks were invented. They remove polling, easing the load on infrastructure, and reduce the "event happened->it got noticed in an external system" latency. However, "webhooks" analog can't work if cluster is behind a firewall. So an agent, running in the cluster, can connect to GitLab, and receive a message when a change happens. Like web hooks, but the actual connection is initiated from the client, not from the server. Then the agent could:

  - Emulate a webhook inside of the cluster

  - Update a Kubernetes object with a new state. It can be a GitLab-specific object with some concrete schema about a Git repository. Then we can have third-parties integrate with us via this object-based API. It can also be some integration-specific object.

- **Real-time data access.** Agent can stream requested data back to GitLab. See the issue [Invert the model GitLab.com uses for Kubernetes integration by leveraging long lived reverse tunnels](https://gitlab.com/gitlab-org/gitlab/-/issues/212810).

- **Feature/component discovery.** GitLab may need a third-party component to be installed in a cluster for a particular feature to work. Agent can do that component discovery. E.g. we need Prometheus for metrics and we probably can find it in the cluster (is this a bad example? it illustrates the idea though).

- **Prometheus PromQL API proxying.** Configure where Prometheus is available in the cluster, and allow GitLab to issue PromQL queries to the in-cluster Prometheus.

- **Better [GitOps](https://www.gitops.tech/) support.** A repository can be used as a IaC repository. On successful CI run on the main repository, a commit is merged into that IaC repository. Commit describes the new desired state of infrastructure in a particular cluster (or clusters). An agent in a corresponding cluster(s) picks up the update and applies it to the objects in the cluster. We can work with Argo-cd/Flux here to try to reuse existing code and integrate with the community-built tools.

- **Infrastructure drift detection.** Monitor and alert on unexpected changes in Kubernetes objects that are managed in the IaC repository. Should support various ways to describe infrastructure (`kustomize`, `helm`, plain YAML, etc).

- **Preview changes to IaC specs** against the current state of the corresponding cluster right in the MR.

- **Live diff.** Building on top of the previous feature. In repository browser when a directory with IaC specs is opened, show a live comparison of what is in the repository and what is in the corresponding cluster.

- **Kubernetes has audit logs.** We could build a page to view them and perhaps correlate with other GitLab events?

- See how we can support [`kubernetes-sigs/application`](https://github.com/kubernetes-sigs/application).

  - In repository browser detect resource specs with the defined annotations and show the relevant meta information bits
  - Have a panel showing live list of installed applications based on the annotations from the specification

- **Emulate Kubernetes API** and proxy it into the actual cluster via the agents (to overcome the firewall).
