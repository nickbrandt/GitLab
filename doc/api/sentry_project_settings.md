# Sentry Project Settings API

## Sentry Error Tracking Project Settings

The Sentry Project Settings API allows you to retrieve Sentry Error Tracking Settings for a Project. Only for project maintainers.

### Retrieve Sentry Error Tracking Settings

```
GET /projects/:id/error_tracking/sentry_project_settings
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID of the project owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/error_tracking/sentry_project_settings
```

Example response:

```json
{
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project"
}
```
