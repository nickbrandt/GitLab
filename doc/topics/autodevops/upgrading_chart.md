# Upgrading auto-deploy-app chart for Auto DevOps

## Compatibility Chart

| GitLab | [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image) (with auto-deploy-app) | Comment |
|--------|--------------|-------------|
| >= v10.0 | >= v0.1.0 and < v2.0.0 | v0 and v1 of charts are backward compatible |

## Upgrade Criteria

- The Auto DevOps project must use the vanilla chart, which managed by GitLab.
  [Customized charts](customize.md#custom-helm-chart) are unsupported.

## Manual Upgrade Guide

### Upgrading to v1 chart

Since v1 chart is backward compatible with v0 chart, you don't need any extra steps,
thus shouldn't encounter [the major version mismatch warning](#major-version-mismatch-warning).

<!-- ### Upgrading to v2
     This is scheduled in upcoming milestone. -->

## Major Version Mismatch Warning

When the major version of the currently deploying chart is different from the previously deployed chart,
the new chart could not be correctly applied to the existing deployment due to architectural change.
In this case, you would see that a deployment job fails with something like the following warning message.

```
*************************************************************************************
                                   [WARNING]                                         
Detected the major version difference between the previously deployed chart (auto-deploy-app-v0.7.0) and the currently deploying chart (auto-deploy-app-v1.0.0).
A new major version likely does not have backward compatibility to the current release (production), therefore the deployment could fail or stuck in an unrecoverable status.
...
```

To resolve the message, please follow [the manual upgrade guide](#manual-upgrade-guide).
Alternatively, you can keep [using a previous verions of chart](#keep-using-a-specific-version-of-chart) for quickly resuming deployments.

### Keep using a specific version of chart

To use a specific version of chart, you must specify a corresponding version of [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image).
You can [customize `.gitlab-ci.yml`](customize.md#customizing-gitlab-ciyml)
for this purpose.

For example, creating the following `.gitlab-ci.yml` file in the project. It specifies `v0.17.0` of [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image)
for deployment jobs, which downloads the latest v0 chart from [chart repository](https://charts.gitlab.io/).

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

.auto-deploy:
  image: "registry.gitlab.com/gitlab-org/cluster-integration/auto-deploy-image:v0.17.0"
```

### Forcibly continue deploying with ignoring the warning

If you are absolutely sure that the new chart version is safe to be deployed on the existing deployment,
you can set `AUTO_DEVOPS_ALLOW_TO_FORCE_DEPLOY_V<N>` [environment variable](customize.md#build-and-deployment) for forecibly contunuing the deployment.

For example, if you want to deploy v2.0.0 chart on a deployment which deployed with v0.17.0 chart, set `AUTO_DEVOPS_ALLOW_TO_FORCE_DEPLOY_V2`.
