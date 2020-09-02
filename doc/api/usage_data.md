# Track Usage Data events

> Introduced in GitLab 13.4

## Increment unique users count using Redis HLL

Increment unique users for given event name.
In order to be able to increment the values the related feature `usage_data<event_name>` should be enabled.

```plaintext
POST /increment_unique_users
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | yes | The event name it should be tracked |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/usage_data/increment_unique_users" --data "name=event_name"
```

### Response

Return 200 if tracking failed for any reason.

- `401 Unauthorized` if not authorized
- `400 Bad request` if name parameter is missing
- `200` if event was tracked or any errors
