# Project remote mirrors API

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/54574) in GitLab 11.3

A project's remote mirrors are it's push mirrors. Remote mirrors are not pull mirrors.

There is
[an issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/51763)
to improve the naming of push and pull mirrors.

## Delete a remote mirror

Deletes an existing project remote mirror. This returns a `204 No Content` status code if the operation was successful or `404` if the resource was not found.

```
DELETE /projects/:id/remote_mirrors/:remote_mirror_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `remote_mirror_id` | integer | yes | The id of the project's remote mirror |


