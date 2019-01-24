# Packages API **[PREMIUM]**

This is the API docs of [GitLab Packages](../administration/packages.md).

## List project packages

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/9259) in GitLab 11.8.

Get a list of project packages. Both Maven and NPM packages are included in results.
When accessed without authentication, only packages of public projects are returned.

```
GET /projects/:id/packages
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/packages
```

Example response:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven"
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm"
  }
]
```

By default, the `GET` request will return 20 results, since the API is [paginated](README.md#pagination).
