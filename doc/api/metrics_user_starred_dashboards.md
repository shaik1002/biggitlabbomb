---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User-starred metrics dashboards API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The starred dashboard feature makes navigating to frequently-used dashboards easier
by displaying favorited dashboards at the top of the select list.

## Add a star to a dashboard

```plaintext
POST /projects/:id/metrics/user_starred_dashboards
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `dashboard_path` | string        | yes      | URL-encoded path to file defining the dashboard which should be marked as favorite.   |

```shell
curl --header 'Private-Token: <your_access_token>' "https://gitlab.example.com/api/v4/projects/20/metrics/user_starred_dashboards" \
 --data-urlencode "dashboard_path=config/prometheus/dashboards/common_metrics.yml"
```

Example Response:

```json
{
  "id": 5,
  "dashboard_path": "config/prometheus/common_metrics.yml",
  "user_id": 1,
  "project_id": 20
}
```

## Remove a star from a dashboard

```plaintext
DELETE /projects/:id/metrics/user_starred_dashboards
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `dashboard_path` | string        | no      | URL-encoded path to file defining the dashboard which should no longer be marked as favorite. When not supplied, all dashboards within given projects are removed from favorites.   |

```shell
curl --request DELETE --header 'Private-Token: <your_access_token>' "https://gitlab.example.com/api/v4/projects/20/metrics/user_starred_dashboards" \
 --data-urlencode "dashboard_path=config/prometheus/dashboards/common_metrics.yml"
```

Example Response:

```json
{
  "deleted_rows": 1
}
```
