# Advanced Global Search index reindexing **(STARTER ONLY)**

>**Note:** This feature was introduced in GitLab 13.2

## Trigger Advanced Global Search reindexing

Trigger zero-downtime background reindexing

```plaintext
PUT /elasticsearch_cluster_reindexing/trigger
```

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/elasticsearch_cluster_reindexing/trigger"
```

Example response:

```json
{
  "job_id": "fd5c5108e4da7b5e3ff0b00b"
}
```
