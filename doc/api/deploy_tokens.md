# Deploy Tokens API

## List all deploy tokens

Get a list of all deploy tokens across all projects of the GitLab instance.

>**Note:**
> This endpoint requires admin access.

```
GET /deploy_tokens
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/deploy_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "token": "jMRvtPNxrn3crTAGukpZ",
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

## Projects

These endpoints require project maintainer access or higher.

### List deploy tokens

Get a list of a project's deploy tokens

```
GET /projects/:id/deploy_tokens
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deploy_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "token": "jMRvtPNxrn3crTAGukpZ",
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### Create a deploy token

Creates a new deploy token for a project.

```
POST /projects/:id/deploy_tokens
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`              | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name`            | string  | yes | New deploy token's name |
| `expires_at`      | datetime | no  | Expiration date for the deploy token. Does not expire if no value is provided. |
| `username`        | string  | no  | Username for deploy token. Default is `gitlab+deploy-token-{n}` |
| `read_repository` | boolean | no  | Token scope: allows read-only access to the repository |
| `read_registry`   | boolean | no  | Token scope: allows read-only access to the registry images |

>**Note:**
> At least one token scope `read_repository` or `read_registry` must be provided.

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "read_repository": "true"}' "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/"
```

Example response:

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "scopes": [
    "read_repository"
  ]
}
```

### Delete a deploy token

Removes a deploy token from the project.

```
DELETE /projects/:id/deploy_tokens/:token_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `token_id`  | integer | yes | The ID of the deploy token |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/13"
```

## Groups

These endpoints require group maintainer access or higher.

### List deploy tokens

Get a list of a group's deploy tokens

```
GET /groups/:id/deploy_tokens
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/deploy_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "token": "jMRvtPNxrn3crTAGukpZ",
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### Create a deploy token

Creates a new deploy token for a group.

```
POST /groups/:id/deploy_tokens
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`              | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name`            | string  | yes | New deploy token's name |
| `expires_at`      | datetime | no  | Expiration date for the deploy token. Does not expire if no value is provided. |
| `username`        | string  | no  | Username for deploy token. Default is `gitlab+deploy-token-{n}` |
| `read_repository` | boolean | no  | Token scope: allows read-only access to the repository |
| `read_registry`   | boolean | no  | Token scope: allows read-only access to the registry images |

>**Note:**
> At least one token scope `read_repository` or `read_registry` must be provided.

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "read_registry": "true"}' "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/"
```

Example response:

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "scopes": [
    "read_registry"
  ]
}
```

### Delete a deploy token

Removes a deploy token from the group.

```
DELETE /groups/:id/deploy_tokens/:token_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `token_id`  | integer | yes | The ID of the deploy token |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/13"
```
