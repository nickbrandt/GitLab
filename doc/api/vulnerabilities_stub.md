# Vulnerabilities API **(ULTIMATE)**

Every API call to vulnerabilities must be [authenticated](README.md#authentication).

Vulnerabilities are project-bound entities. If a user is not
a member of a project to which vulnerability belongs
and the project is private, a request on that project
will result in a `404` status code.

CAUTION: **Caution:**
This API is in an alpha stage and considered unstable.
The response payload may be subject to change or breakage
across GitLab releases.

## Single vulnerability

Gets a single vulnerability

```
GET /vulnerabilities/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of a Vulnerability to get |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/vulnerabilities/1
```

Example response:

```json
{
  "id": 1,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "opened",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "updated_by_id": null,
  "last_edited_by_id": null,
  "closed_by_id": null,
  "start_date": null,
  "due_date": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "last_edited_at": null,
  "closed_at": null
}
```

## Resolve vulnerability

Resolves a given vulnerability. Returns status code `304` if the vulnerability is already resolved.

If an authenticated user does not have permission to
[resolve vulnerabilities](../user/permissions_stub_first_class_vulnerabilities.md#project-members-permissions),
this request will result in a `403` status code.

```
POST /vulnerabilities/:id/resolve
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of a Vulnerability to resolve |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/vulnerabilities/5/resolve"
```

Example response:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "resolved",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "updated_by_id": null,
  "last_edited_by_id": null,
  "closed_by_id": null,
  "start_date": null,
  "due_date": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "last_edited_at": null,
  "closed_at": null
}
```

## Dismiss vulnerability

Dismisses a given vulnerability. Returns status code `304` if the vulnerability is already dismissed.

If an authenticated user does not have permission to
[dismiss vulnerabilities](../user/permissions_stub_first_class_vulnerabilities.md#project-members-permissions),
this request will result in a `403` status code.

```
POST /vulnerabilities/:id/dismiss
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of a vulnerability to dismiss |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/vulnerabilities/5/dismiss"
```

Example response:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "closed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "updated_by_id": null,
  "last_edited_by_id": null,
  "closed_by_id": null,
  "start_date": null,
  "due_date": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "last_edited_at": null,
  "closed_at": null
}
```
