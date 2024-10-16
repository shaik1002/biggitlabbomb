---
stage: Monitor
group: Observability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Logs

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143027) in GitLab 16.10 [with a flag](../administration/feature_flags.md) named `observability_logs`. Disabled by default. This feature is in [beta](../policy/experiment-beta-support.md#beta).

FLAG:
This feature is only available on GitLab.com. On self-managed GitLab and GitLab Dedicated, by default this feature is not available.
This feature is not ready for production use.

GitLab supports centralized application and infrastructure logs collection, storage, and analysis.
GiLab Logging provides insight about the operational health of monitored systems.
Use logs to learn more about your systems and applications in a given range of time.

## Configure logging

Configure logging to enable it for a project.

Prerequisites:

- You must have at least the Maintainer role for the project.

1. Create an access token and enable logs:
   1. On the left sidebar, select **Search or go to** and find your project.
   1. Select **Settings > Access Tokens**.
   1. Create an access token with the following scopes: `read_api`, `read_observability`, `write_observability`. Be sure to save the access token value for later.
   1. Select **Monitor > Logs**, and then select **Enable**.
1. To configure your application to send GitLab logs, set the following environment variables:

   ```shell
   OTEL_EXPORTER = "otlphttp"
   OTEL_EXPORTER_OTLP_LOGS_ENDPOINT = "https://observe.gitlab.com/v3/<namespace-id>/<gitlab-project-id>/ingest/logs"
   OTEL_EXPORTER_OTLP_LOGS_HEADERS = "PRIVATE-TOKEN=<gitlab-access-token>"
   ```

   Use the following values:

   - `namespace-id` - The top-level group ID that contains the project
   - `gitlab-project-id` - The project ID
   - `gitlab-access-token` - The access token you created

Logs are configured for your project.
When you run your application, the OpenTelemetry exporter sends logs to GitLab.

## View logs

You can view the logs for a given project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Monitor > Logs**.

A list of logs is displayed. Currently log date, level, service, and message are supported.
Select a log line to view its details.

You can either filter logs by attribute or query log strings with the search bar.
The log volume chart at the top shows the number of logs ingested over the given time period.

![list of logs](img/logs_list_v17_1.png)

### View logs details

It is also possible to see log line details such as metadata and resource attributes.

![logs details](img/logs_details_v17_1.png)
