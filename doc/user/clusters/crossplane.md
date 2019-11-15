# Crossplane configuration guide

## Introduction

In order to allow Crossplane to provision cloud services such as Postgres, it requires the cloud provider stack to be configured with a user account (eg: a service account in case of GCP, an IAM user in case of AWS).

For this guide the pre-requisites are as follows:

- Crossplane was previously installed as a [GitLab Managed App](./applications.md#crossplane) on the connected kubernetes cluster with a choice of the stack.

We will use the GCP stack as an example in this guide. The instructions for AWS and Azure will be similar to this.

> Note: Crossplane requires the kubernetes cluster to be VPC Native with Alias IPs enabled so that the IP address of the Pods are routable within the GCP network.

First, we need to declare some environment variables with configuration that will be used throughout this guide:

```sh
export PROJECT_ID=crossplane-playground # the project that all resources reside.
export NETWORK_NAME=default # the network that your GKE cluster lives in.
export REGION=us-central1 # the region where the GKE cluster lives in.
```

### Configure RBAC permissions

- For a non-GitLab managed cluster(s), ensure that the service account for the token provided can manage resources in the `database.crossplane.io` API group.
We need to manually grant GitLab's service account the ability to manage resources in the database.crossplane.io API group. The Aggregated ClusterRole allows us to do that.
First, save the following YAML as `crossplane-database-role.yaml`

```sh
cat > crossplane-database-role.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: crossplane-database-role
  labels:
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
rules:
- apiGroups:
  - database.crossplane.io
  resources:
  - postgresqlinstances
  verbs:
  - get
  - list
  - create
  - update
  - delete
  - patch
  - watch
EOF
```

```sh
kubectl apply -f crossplane-database-role.yaml
```

### Configure Crossplane with the cloud provider

Follow the steps to configure the installed cloud provider stack with a user account.
> **Note: The Secret and the Provider resource referencing the Secret needs to be applied to the `gitlab-managed-apps` namespace in the guide. Make sure you change that while following the guide**

[Configure Providers](https://crossplane.io/docs/v0.4/cloud-providers.html)

### Configure Managed Service Access

We need to configure connectivity between the Postgres database and the GKE cluster. This can be configured by creating a [Private Service Connection](https://cloud.google.com/vpc/docs/configure-private-services-access)

We can either use Crossplane to achieve this as demonstrated below or directly in the GCP console by following the above link.

- Create a GlobalAddress and Connection resources:

```sh
cat > network.yaml <<EOF
---
# gitlab-ad-globaladdress defines the IP range that will be allocated for cloud services connecting to the instances in the given Network.

apiVersion: compute.gcp.crossplane.io/v1alpha3
kind: GlobalAddress
metadata:
  name: gitlab-ad-globaladdress
spec:
  providerRef:
    name: gcp-provider
  reclaimPolicy: Delete
  name: gitlab-ad-globaladdress
  purpose: VPC_PEERING
  addressType: INTERNAL
  prefixLength: 16
  network: projects/$PROJECT_ID/global/networks/$NETWORK_NAME
---
# gitlab-ad-connection is what allows cloud services to use the allocated GlobalAddress for communication. Behind
# the scenes, it creates a VPC peering to the network that those service instances actually live.

apiVersion: servicenetworking.gcp.crossplane.io/v1alpha3
kind: Connection
metadata:
  name: gitlab-ad-connection
spec:
  providerRef:
    name: gcp-provider
  reclaimPolicy: Delete
  parent: services/servicenetworking.googleapis.com
  network: projects/$PROJECT_ID/global/networks/$NETWORK_NAME
  reservedPeeringRangeRefs:
    - name: gitlab-ad-globaladdress
EOF
```

```sh
kubectl apply -f network.yaml
```

You can verify creation of the network resources with the following commands.
Verify that the status of both of these resources is ready and is synced.

```sh
kubectl describe connection.servicenetworking.gcp.crossplane.io gitlab-ad-connection

kubectl describe globaladdress.compute.gcp.crossplane.io gitlab-ad-globaladdress
```

### Setup Resource classes

Resource classes are a way of defining a configuration for the required managed service. We will define the Postgres Resource class

- Define a gcp-postgres-standard.yaml resourceclass which contains

1. A default CloudSQLInstanceClass.
1. A CloudSQLInstanceClass with labels.

```sh
cat > gcp-postgres-standard.yaml <<EOF
apiVersion: database.gcp.crossplane.io/v1beta1
kind: CloudSQLInstanceClass
metadata:
  name: cloudsqlinstancepostgresql-standard
  labels:
    gitlab-ad-demo: "true"
specTemplate:
  writeConnectionSecretsToNamespace: gitlab-managed-apps
  forProvider:
    databaseVersion: POSTGRES_9_6
    region: $REGION
    settings:
      tier: db-custom-1-3840
      dataDiskType: PD_SSD
      dataDiskSizeGb: 10
      ipConfiguration:
        privateNetwork: projects/$PROJECT_ID/global/networks/$NETWORK_NAME
  # this should match the name of the provider created in the above step
  providerRef:
    name: gcp-provider
  reclaimPolicy: Delete
---
apiVersion: database.gcp.crossplane.io/v1beta1
kind: CloudSQLInstanceClass
metadata:
  name: cloudsqlinstancepostgresql-standard-default
  annotations:
    resourceclass.crossplane.io/is-default-class: "true"
specTemplate:
  writeConnectionSecretsToNamespace: gitlab-managed-apps
  forProvider:
    databaseVersion: POSTGRES_9_6
    region: $REGION
    settings:
      tier: db-custom-1-3840
      dataDiskType: PD_SSD
      dataDiskSizeGb: 10
      ipConfiguration:
        privateNetwork: projects/$PROJECT_ID/global/networks/$NETWORK_NAME
  # this should match the name of the provider created in the above step
  providerRef:
    name: gcp-provider
  reclaimPolicy: Delete
EOF
```

```sh
kubectl apply -f gcp-postgres-standard.yaml

```

Verify creation of the Resource class

```sh
kubectl get cloudsqlinstanceclasses
```

The Resource Classes allow you to define classes of service for a managed service. We could create another `CloudSQLInstanceClass` which requests for a larger or a faster disk. It could also request for a specific version of the database.

### Auto DevOps Configuration Options

The Auto DevOps pipeline can be run with the following options:

1. `postgres.managed` set to true which will select a default resourceclass. The resourceclass needs to be marked with the annotation `resourceclass.crossplane.io/is-default-class: "true"` (As per the guide the CloudSQLInstanceClass `cloudsqlinstancepostgresql-standard-default` will be used to satisfy the claim )

1. `postgres.managed` set to true with `postgres.managedClassSelector` providing the resource class to choose based on labels. In this case the value of `postgres.managedClassSelector.matchLabels.gitlab-ad-demo="true"` will select the CloudSQLInstance class `cloudsqlinstancepostgresql-standard` to satisfy the claim request.

Alertnatively, the Environment variables `AUTO_DEVOPS_POSTGRES_MANAGED` and `AUTO_DEVOPS_POSTGRES_MANAGED_CLASS_SELECTOR` could also be used in the Auto DevOps pipeline.

The Auto DevOps pipeline should provision a PostgresqlInstance when it runs succesfully.

Verify creation of the PostgresQL Instance.

```sh
kubectl get postgresqlinstance
```

Sample Output: The `STATUS` field of the PostgresqlInstance transitions to `BOUND` when it is successfully provisioned.

```
NAME            STATUS   CLASS-KIND              CLASS-NAME                            RESOURCE-KIND      RESOURCE-NAME                               AGE
staging-test8   Bound    CloudSQLInstanceClass   cloudsqlinstancepostgresql-standard   CloudSQLInstance   xp-ad-demo-24-staging-staging-test8-jj55c   9m
```

The endpoint of the PostgreSQL instance, and the user credentials, are present in a secret called `app-postgres` within the same project namespace.

Verify the secret with the database information is created.

```sh
kubectl describe secret app-postgres
```

Sample Output:

```
Name:         app-postgres
Namespace:    xp-ad-demo-24-staging
Labels:       <none>
Annotations:  crossplane.io/propagate-from-name: 108e460e-06c7-11ea-b907-42010a8000bd
              crossplane.io/propagate-from-namespace: gitlab-managed-apps
              crossplane.io/propagate-from-uid: 10c79605-06c7-11ea-b907-42010a8000bd

Type:  Opaque

Data
====
privateIP:                            8 bytes
publicIP:                             13 bytes
serverCACertificateCert:              1272 bytes
serverCACertificateCertSerialNumber:  1 bytes
serverCACertificateCreateTime:        24 bytes
serverCACertificateExpirationTime:    24 bytes
username:                             8 bytes
endpoint:                             8 bytes
password:                             27 bytes
serverCACertificateCommonName:        98 bytes
serverCACertificateInstance:          41 bytes
serverCACertificateSha1Fingerprint:   40 bytes

```

### Connect to the PostgresQL instance

Follow this [GCP guide](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine) if you
would like to connect to the newly provisioned Postgres database instance on CloudSQL.
