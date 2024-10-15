---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting GitLab for Jira Cloud app administration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

When administering the GitLab for Jira Cloud app, you might encounter the following issues.

For user documentation, see [GitLab for Jira Cloud app](../../integration/jira/connect-app.md#troubleshooting).

## Sign-in message displayed when already signed in

You might get the following message prompting you to sign in to GitLab.com
when you're already signed in:

```plaintext
You need to sign in or sign up before continuing.
```

The GitLab for Jira Cloud app uses an iframe to add groups on the
settings page. Some browsers block cross-site cookies, which can lead to this issue.

To resolve this issue, set up [OAuth authentication](jira_cloud_app.md#set-up-oauth-authentication).

## Manual installation fails

You might get one of the following errors if you've installed the GitLab for Jira Cloud app
from the official marketplace listing and replaced it with [manual installation](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually):

```plaintext
The app "gitlab-jira-connect-gitlab.com" could not be installed as a local app as it has previously been installed from Atlassian Marketplace
```

```plaintext
The app host returned HTTP response code 401 when we tried to contact it during installation. Please try again later or contact the app vendor.
```

To resolve this issue, disable the **Jira Connect Proxy URL** setting.

- In GitLab 15.7:

  1. Open a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session).
  1. Execute `ApplicationSetting.current_without_cache.update(jira_connect_proxy_url: nil)`.

- In GitLab 15.8 and later:

  1. On the left sidebar, at the bottom, select **Admin Area**.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **GitLab for Jira App**.
  1. Clear the **Jira Connect Proxy URL** text box.
  1. Select **Save changes**.

If the issue persists, verify that your self-managed GitLab instance can connect to
`connect-install-keys.atlassian.com` to get the public key from Atlassian.
To test connectivity, run the following command:

```shell
# A `404 Not Found` is expected because you're not passing a token
curl --head "https://connect-install-keys.atlassian.com"
```

## Data sync fails with `Invalid JWT`

If the GitLab for Jira Cloud app continuously fails to sync data from a self-managed GitLab instance,
a secret token might be outdated. Atlassian can send new secret tokens to GitLab.
If GitLab fails to process or store these tokens, an `Invalid JWT` error occurs.

To resolve this issue on your self-managed GitLab instance:

- Confirm your self-managed GitLab instance is publicly available to:
  - GitLab.com (if you [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#connect-the-gitlab-for-jira-cloud-app)).
  - Jira Cloud (if you [installed the app manually](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)).
- Ensure the token request sent to the `/-/jira_connect/events/installed` endpoint when you install the app is accessible from Jira.
  The following command should return a `401 Unauthorized`:

  ```shell
  curl --include --request POST "https://gitlab.example.com/-/jira_connect/events/installed"
  ```

- If your self-managed GitLab instance has [SSL configured](https://docs.gitlab.com/omnibus/settings/ssl/), check your
  [certificates are valid and publicly trusted](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html#useful-openssl-debugging-commands).

Depending on how you installed the app, you might want to check the following:

- If you [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#connect-the-gitlab-for-jira-cloud-app),
  switch between GitLab versions in the GitLab for Jira Cloud app:

<!-- markdownlint-disable MD044 -->

  1. In Jira, on the top bar, select **Apps > Manage your apps**.
  1. Expand **GitLab for Jira (gitlab.com)**.
  1. Select **Get started**.
  1. Select **Change GitLab version**.
  1. Select **GitLab.com (SaaS)**, then select **Save**.
  1. Select **Change GitLab version** again.
  1. Select **GitLab (self-managed)**, then select **Next**.
  1. Select all checkboxes, then select **Next**.
  1. Enter your **GitLab instance URL**, then select **Save**.

<!-- markdownlint-enable MD044 -->

  If this method does not work, [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new) if you're a Premium or Ultimate customer.
  Provide your GitLab instance URL and Jira URL. GitLab Support can try to run the following scripts to resolve the issue:

  ```ruby
  # Check if GitLab.com can connect to the self-managed instance
  checker = Gitlab::TcpChecker.new("gitlab.example.com", 443)

  # Returns `true` if successful
  checker.check

  # Returns an error if the check fails
  checker.error
  ```

  ```ruby
  # Locate the installation record for the self-managed instance
  installation = JiraConnectInstallation.find_by_instance_url("https://gitlab.example.com")

  # Try to send the token again from GitLab.com to the self-managed instance
  ProxyLifecycleEventService.execute(installation, :installed, installation.instance_url)
  ```

- If you [installed the app manually](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually):
  - Ask [Jira Cloud Support](https://support.atlassian.com/jira-software-cloud/) to verify that Jira can connect to your
    self-managed GitLab instance.
  - [Reinstall the app](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually). This method might remove all [synced data](../../integration/jira/connect-app.md#gitlab-data-synced-to-jira) from the [Jira development panel](../../integration/jira/development_panel.md).

## `Failed to update the GitLab instance`

When you set up the GitLab for Jira Cloud app, you might get a `Failed to update the GitLab instance` error after you enter your self-managed instance URL.

To resolve this issue, ensure all prerequisites for your installation method have been met:

- [Prerequisites for connecting the GitLab for Jira Cloud app](jira_cloud_app.md#prerequisites)
- [Prerequisites for installing the GitLab for Jira Cloud app manually](jira_cloud_app.md#prerequisites-1)

If you have configured a Jira Connect Proxy URL and the problem persists after checking the prerequisites, review [Debugging Jira Connect Proxy issues](#debugging-jira-connect-proxy-issues).

If you're using GitLab 15.8 and earlier and have previously enabled both the `jira_connect_oauth_self_managed`
and the `jira_connect_oauth` feature flags, you must disable the `jira_connect_oauth_self_managed` flag
due to a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388943). To check for these flags:

1. Open a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Execute the following code:

   ```ruby
   # Check if both feature flags are enabled.
   # If the flags are enabled, these commands return `true`.
   Feature.enabled?(:jira_connect_oauth)
   Feature.enabled?(:jira_connect_oauth_self_managed)

   # If both flags are enabled, disable the `jira_connect_oauth_self_managed` flag.
   Feature.disable(:jira_connect_oauth_self_managed)
   ```

### Debugging Jira Connect Proxy issues

If you set **Jira Connect Proxy URL** to `https://gitlab.com` when you
[set up your instance](jira_cloud_app.md#set-up-your-instance), you can:

- Inspect the network traffic in your browser's development tools.
- Reproduce the `Failed to update the GitLab instance` error for more information.

You should see a `GET` request to `https://gitlab.com/-/jira_connect/installations`.

This request should return a `200 OK`, but it might return a `422 Unprocessable Entity` if there was a problem.
You can check the response body for the error.

If you cannot resolve the issue and you're a GitLab customer, contact [GitLab Support](https://about.gitlab.com/support/) for assistance.
Provide GitLab Support with:

- Your self-managed instance URL.
- Your GitLab.com username.
- Optional. The `X-Request-Id` response header for the failed `GET`
  request to `https://gitlab.com/-/jira_connect/installations`.
- Optional. [A HAR file](https://support.zendesk.com/hc/en-us/articles/4408828867098-Generating-a-HAR-file-for-troubleshooting)
  you've processed with [`harcleaner`](https://gitlab.com/gitlab-com/support/toolbox/harcleaner) that captures the issue.

GitLab Support can then investigate the issue in the GitLab.com server logs.

#### GitLab Support

NOTE:
These steps can only be completed by GitLab Support.

[In Kibana](https://log.gprd.gitlab.net/app/r/s/0FdPP), the logs should be filtered for
`json.meta.caller_id: JiraConnect::InstallationsController#update` and `NOT json.status: 200`.
If you have been provided the `X-Request-Id` value, you can use that against `json.correlation_id` to narrow down the results.

Each `GET` request to the Jira Connect Proxy URL `https://gitlab.com/-/jira_connect/installations` generates two log entries.

For the first log:

- `json.status` is `422 Unprocessable Entity`.
- `json.params.value` should match the self-managed GitLab URL `[[FILTERED], {"instance_url"=>"https://gitlab.example.com"}]`.

For the second log, you might have one of the following scenarios:

- Scenario 1:
  - `json.message`, `json.jira_status_code`, and `json.jira_body` are present.
  - `json.message` is `Proxy lifecycle event received error response` or similar.
  - `json.jira_status_code` and `json.jira_body` might contain the response received from the self-managed instance or a proxy in front of the instance.
  - If `json.jira_status_code` is `401 Unauthorized` and `json.jira_body` is empty:
    - [**Jira Connect Proxy URL**](jira_cloud_app.md#set-up-your-instance) might not be set to `https://gitlab.com`.
    - If a [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy) is in front of your self-managed instance,
      the `Host` header sent to the self-managed instance might not match the reverse proxy FQDN.
      Check the [Workhorse logs](../logs/index.md#workhorse-logs) on the self-managed instance:

      ```shell
      grep /-/jira_connect/events/installed /var/log/gitlab/gitlab-workhorse/current
      ```

      The output might contain the following:

      ```json
      {
        "host":"gitlab.mycompany.com:443", // The host should match the reverse proxy FQDN entered into the GitLab for Jira Cloud app
        "remote_ip":"34.74.226.3", // This IP should be within the GitLab.com IP range https://docs.gitlab.com/ee/user/gitlab_com/#ip-range
        "status":401,
        "uri":"/-/jira_connect/events/installed"
      }
      ```

- Scenario 2:
  - `json.exception.class` and `json.exception.message` are present.
  - `json.exception.class` and `json.exception.message` contain whether an issue occurred while contacting the self-managed instance.

## `Failed to link group`

When you link a group, you might get the following error:

```plaintext
Failed to link group. Please try again.
```

A `403 Forbidden` is returned if the user information cannot be fetched from Jira because of insufficient permissions.

To resolve this issue, ensure the Jira user that installs and configures the app
meets certain [requirements](jira_cloud_app.md#jira-user-requirements).

This error might also occur if you use a rewrite or subfilter with a [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy).
The app key used in requests contains part of the server hostname, which some reverse proxy filters might capture.
The app key in Atlassian and GitLab must match for authentication to work correctly.

## `Failed to load Jira Connect Application ID`

When you sign in to the GitLab for Jira Cloud app after you point the app
to your self-managed instance, you might get the following error:

```plaintext
Failed to load Jira Connect Application ID. Please try again.
```

When you check the browser console, you might also see the following message:

```plaintext
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at https://gitlab.example.com/-/jira_connect/oauth_application_id. (Reason: CORS header 'Access-Control-Allow-Origin' missing). Status code: 403.
```

To resolve this issue:

1. Ensure `/-/jira_connect/oauth_application_id` is publicly accessible and returns a JSON response:

   ```shell
   curl --include "https://gitlab.example.com/-/jira_connect/oauth_application_id"
   ```

1. If you [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#connect-the-gitlab-for-jira-cloud-app),
   ensure [**Jira Connect Proxy URL**](jira_cloud_app.md#set-up-your-instance) is set to `https://gitlab.com` without leading slashes.
