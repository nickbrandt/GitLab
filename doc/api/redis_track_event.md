# Track events using Redis HyperLogLog

Track unique events using Redis HyperLogLog

> Introduced in GitLab 13.4

## Track unique users count using Redis HLL

```plaintext
POST /redis_track_event
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | yes | The event name it should be tracked |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/redis_track_event" --data "name=event_name"
```

### Response

Return 200 if tracking failed for any reason.

- `401 Unauthorized` if not authorized
- `400 Bad request` if name parameter is missing
- `200` if event was tracked or any errors
