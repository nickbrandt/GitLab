---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrating from GitLab managed apps to a [management project tempalte](management_project_template.md)

1. Read how the [management project tempalte](management_project_template.md) works.
1. Create a new project as explained in the [management project tempalte](management_project_template.md).
1. Detect apps deployed through Helm v2 releases.

   For this, you can use the preconfigured [`.gitlab-ci.yml`](management_project_template.md#the-gitlab-ciyml).
   In case you had ovewritten the default GitLab managed apps namespace, make sure that the 
   [`./gl-fail-if-helm2-releases-exist`](management_project_template.md#the-gitlab-ciyml) script is receiving the 
   correct namespace as an argument. If you kept the default (`gitlab-managed-apps`), then the script is already 
   setup. So, [run a pipeline manually](../../ci/pipelines/index.md#run-a-pipeline-manually) and read the logs of the
   `detect-helm2-releases` job to know if you have any Helm v2 releases and which are they.

1. If you have no Helm v2 releases, jump to the next step. Otherwise, follow the official Helm docs on
   [how to migrate from Helm v2 to Helm v3 and cleanup the
   Helm v2 releases](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/) after you are confident that they have been
   successfully migrated.
1. In this step you should already have only Helm v3 releases.
   Uncomment from the main [`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml) the paths for the
   applications that you would like to manage with this project. Although you could uncomment all the ones you want to
   managed at once, we recommend you repeat the following steps separately for each app, so you do not get lost during
   the process. So, pick one of your apps and uncomment its `- path: applications/{app}/helmfile.yaml`.
1. Edit the associated `./applications/{app}/helmfiles.yaml` in this project to match the chart version currently deployed 
   for your app. Take a GitLab Runner Helm v3 release as an example:
   
   The following command lists the releases and their versions:

   ```shell
   ~> helm ls -n gitlab-managed-apps
   NAME NAMESPACE REVISION UPDATED STATUS CHART APP VERSION
   runner gitlab-managed-apps 1 2021-06-09 19:36:55.739141644 +0000 UTC deployed gitlab-runner-0.28.0 13.11.0
   ```

   Take the version from the `CHART` column which is in the format `{release}-v{chart_version}`,
   then edit the `version:` attribute in the `./applications/gitlab-runner/helmfile.yaml`, so that it matches the version
   you have currently deployed. This is a safe step to avoid upgrading versions during this migration.
   Make sure you replace `gitlab-managed-apps` from the above command if you have your apps deployed to a different
   namespace.

1. Edit the `./applications/{app}/values.yaml` associated with your app to match the currently
   deployed values. E.g. for GitLab Runner:

   Copy the output of below the command below, which might be big:
   
   ```shell
   ~> helm get values runner -n gitlab-managed-apps -a --output yaml
   ```

   and overwrite the `./applications/gitlab-runner/values.yaml` with these output of the above command.
   This safe step will guarantee that no unexpected default values overwrite your currently deployed values.
   For instance, your GitLab Runner could have its `gitlabUrl` or `runnerRegistrationToken` overwritten by mistake.

1. Some apps might special conditions

   Ingress: Because of an existing [chart issue](https://github.com/helm/charts/pull/13646) you might see 
   `spec.clusterIP: Invalid value` when trying to run the [`./gl-helmfile`](management_project_template.md#the-gitlab-ciyml) 
   command. To workaround this, after overwriting the release values in your `./applications/ingress/values.yaml`, 
   you might need to overwrite all the occurrences of `omitClusterIP:false`, setting it to `omitClusterIP: true`. 
   Another approach, could be to collect these IPs by running the command `kubectl get services -n gitlab-managed-apps`
   and then overwriting each `ClusterIP` that it complains about with the value you got from that command.
   
   Vault: This application introduces a breaking change from the chart we used in Helm v2 to the chart
   used in Helm v3. So the only way to integrate it with this project is actually to uninstall this app and accept the
   chart version proposed in `./applications/vault/values.yaml`.

1. Apply the changes

   After following all the above steps you could [run a pipeline manually](../../ci/pipelines/index.md#run-a-pipeline-manually)
   and watch `apply` job logs to see if your applications were successfully detected, installed and if they got any
   unexpected updates.

   Some annotation checksums are expected to be updated, as well as this attribute:

   ```diff
   --- heritage: Tiller
   +++ heritage: Tiller
   ```

   After getting a successful pipeline, go ahead and repeat these steps for the other apps that you have deployed
   and would like to manage with this project.
