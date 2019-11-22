# Project Vulnerabilities API **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/10242) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.6.

CAUTION: **Caution:**
This API is currently in development and is protected by a **disabled**
[feature flag](https://docs.gitlab.com/ee/development/feature_flags/).
On a self-managed GitLab instance, an administrator can enable it by starting the Rails console
(`sudo gitlab-rails console`) and then running the following command: `Feature.enable(:first_class_vulnerabilities)`.
To test if the Vulnerabilities API was successfully enabled, run the following command:
`Feature.enabled?(:first_class_vulnerabilities)`.

CAUTION: **Caution:**
This API is in an alpha stage and considered unstable.
The response payload may be subject to change or breakage
across GitLab releases.

Every API call to vulnerabilities must be [authenticated](README.md#authentication).

Vulnerabilities are project-bound entities. If a user is not
a member of a project to which the vulnerability belongs
and the project is private, a request on that project
will result in a `404` status code.

## Vulnerabilities pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](README.md#pagination).

## List project vulnerabilities

List all of a project's vulnerabilities.

If an authenticated user does not have permission to
[use the Project Security Dashboard](../user/permissions_stub_first_class_vulnerabilities.md#project-members-permissions),
`GET` requests for vulnerabilities of this project will result in a `403` status code.

```
GET /projects/:id/vulnerabilities
```

| Attribute     | Type           | Required | Description                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user.                                                            |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/4/vulnerabilities
```

Example response:

```json
[
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
  },
  {
    "id": 3,
    "title": "ECB mode is insecure",
    "description": null,
    "state": "opened",
    "severity": "medium",
    "confidence": "high",
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
    "created_at": "2019-10-16T11:19:21.691Z",
    "updated_at": "2019-10-16T11:19:21.691Z",
    "last_edited_at": null,
    "closed_at": null
  }
]
```

## New vulnerability

Creates a new vulnerability.

If an authenticated user does not have a permission to
[create vulnerability](../user/permissions_stub_first_class_vulnerabilities.md#project-members-permissions),
this request will result in a `403` status code.

```
POST /projects/:id/vulnerabilities?finding_id=<your_finding_id>
```

| Attribute           | Type             | Required   | Description                                                                                                                  |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) which the authenticated user is a member of  |
| `finding_id`        | integer/string   | yes        | The ID of a Vulnerability Finding from which the new Vulnerability will be created                                           |

The rest of the attributes of a newly created Vulnerability are populated from
its source Vulnerability Finding or with their default values:

| Attribute    | Value                                                 |
|--------------|-------------------------------------------------------|
| `author`     | The authenticated user                                |
| `title`      | The `name` attribute of a Vulnerability Finding       |
| `state`      | `opened`                                              |
| `severity`   | The `severity` attribute of a Vulnerability Finding   |
| `confidence` | The `confidence` attribute of a Vulnerability Finding |

```bash
curl --header POST "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/vulnerabilities?finding_id=1
```

Example response:

```json
{
  "id": 2,
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

Errors:

_A Vulnerability Finding is not found or already attached to a different Vulnerability_

Occurs when a Finding chosen to create a Vulnerability from is not found or
is already associated with a different Vulnerability.

Status code: `400`

Example response:

```json
{
  "message": {
    "base": [
      "finding is not found or is already attached to a vulnerability"
    ]
  }
}
```
