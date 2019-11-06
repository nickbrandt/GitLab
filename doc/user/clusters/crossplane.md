# Crossplane configuration guide

## Introduction

In order to allow crossplane to provision cloud services such as Postgres, it requires the cloud provider stack to be configured with a user account (eg: a service account in case of gcp, an iam user in case of aws)

For this guide the pre-requisites are as follows:

- Crossplane installed on the connected kubernetes cluster for the gitlab project with a choice of the stack.

We will use the gcp stack as an example in this guide. The instructions for aws and azure will be similar to this. 

```
export PROJECT_ID=crossplane-playground # the project that all resources reside.
export NETWORK_NAME=default # the network that your GKE cluster lives in. 
export SUBNETWORK_NAME=default # the subnetwork that your GKE cluster lives in.
```

### Configure Crossplane with the cloud provider

Follow the steps to configure the installed cloud provider stack with a user account.
[Configure Providers](https://crossplane.io/docs/v0.4/cloud-providers.html)

### Configure Managed Service Access

We need to configure connectivity between the Postgres database and the GKE cluster. This can be configured by creating a [Private Service Connection](https://cloud.google.com/vpc/docs/configure-private-services-access)

We can use crossplane to achieve this or by following the above link.

- Create a GlobalAddress and Connection resources:

```
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

kubectl apply -f network.yaml
```

You can verify creation with the following command and output:

Command

```

kubectl describe connection.servicenetworking.gcp.crossplane.io gitlab-ad-connection
```

### Setup Resource classes

Resource classes are a way of defining a configuration for the required managed service. We will define the Postgres Resource class

- Define a gcp-postgres-standard.yaml resourceclass

```
cat > gcp-postgres-standard.yaml <<EOF
apiVersion: database.gcp.crossplane.io/v1beta1
kind: CloudSQLInstanceClass
metadata:
  name: cloudsqlinstancepostgresql-standard
  labels:
    gitlab-ad-demo: "true"
specTemplate:
  writeConnectionSecretsToNamespace: crossplane-system
  forProvider:
    databaseVersion: POSTGRES_9_6
    region: us-west2
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

kubectl apply -f gcp-postgres-standard.yaml

```

Verify creation of the Resource class

```
kubectl get cloudsqlinstanceclasses
```

The Resource Classes allow you to define classes of service for a managed service. We could create another `CloudSQLInstanceClass` which requests for a larger or a faster disk. It could also request for a specific version of the database.

The autodevops pipeline can be run with the following options:
a) `postgres.managed` set to true which will select a default resourceclass . The resourceclass needs to be marked with `resourceclass.crossplane.io/is-default-class: "true"`
b) `postgres.managed` set to true with `postgres.managedClassSelector` providing the resource class to choose based on labels

The autodevops pipeline should provision a PostgresqlInstance.

Verify creation of the Postgres Instance

```
kubectl get postgresqlinstance
```

### Connect to the Postgres instance

Follow the [guide](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine) to connect to the Postgres database instance provisioned on CloudSQL
