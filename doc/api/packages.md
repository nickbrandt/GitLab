# Packages API

## List project packages

> [Introduced][ee-9259] in GitLab 11.8.

Get a list of project packages. Both Maven and NPM packages are included in results.
When accessed without authentication, only packages of public projects are returned.

```
GET /projects/:id/packages
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

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

By default, `GET` request return 20 results at a time because the API results
are paginated.

Read more on [pagination](README.md#pagination).

This API is for listing project packages. For how to upload or install 
Maven or NPM packages please visit [Packages](../administration/packages.md) documentation.

[ee-9259]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/9259
