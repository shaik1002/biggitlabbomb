---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Control GitLab Duo availability

> - [Settings to turn off AI features introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10.
> - [Settings to turn off AI features added to the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) in GitLab 16.11.

GitLab Duo features that are generally available are automatically turned on for all users that have access.

## Prerequisites

- If you have self-managed GitLab:
  - You must [allow connectivity](#configure-gitlab-duo-on-a-self-managed-instance).
  - [Silent Mode](../../administration/silent_mode/index.md) must not be turned on.
  - You must [activate your instance with an activation code](../../administration/license.md#activate-gitlab-ee).
  - GitLab Duo requires GitLab 17.2 and later for the best user experience and results. Earlier versions may continue to work, however the experience may be degraded.
- If you have GitLab Dedicated, you must have [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md).
- For some generally available features, like [Code Suggestions](../project/repository/code_suggestions/index.md),
  [you must assign seats](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)
  to the users you want to have access.

GitLab Duo features that are experimental or beta are turned off by default
and [must be turned on](#turn-on-beta-and-experimental-features).

## Configure GitLab Duo on a self-managed instance

To use GitLab Duo on a self-managed instance, you must ensure both outbound and inbound connectivity exists.

For example, network firewalls can cause lag or delay. Check both your outbound and inbound settings:

### Allow outbound connections from the GitLab instance

- Your firewalls and HTTP/S proxy servers must allow outbound connections
  to `cloud.gitlab.com` and `customers.gitlab.com` on port `443` both with `https://`.
  These hosts are protected by Cloudflare. Update your firewall settings to allow traffic to
  all IP addresses in the [list of IP ranges Cloudflare publishes](https://www.cloudflare.com/ips/).
- To use an HTTP/S proxy, both `gitLab_workhorse` and `gitLab_rails` must have the necessary
  [web proxy environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html) set.
- In multi-node GitLab installations, configure the HTTP/S proxy on all **Rails** and **Sidekiq** nodes.

### Allow inbound connections from clients to the GitLab instance

- GitLab instances must allow inbound connections from Duo clients ([IDEs](../../editor_extensions/index.md),
  Code Editors, and GitLab Web Frontend) on port 443 with `https://` and `wss://`.
- Both `HTTP2` and the `'upgrade'` header must be allowed, because GitLab Duo
  uses both REST and WebSockets.
- Check for restrictions on WebSocket (`wss://`) traffic to `wss://gitlab.example.com/-/cable` and other `.com` domains.
  Network policy restrictions on `wss://` traffic can cause issues with some GitLab Duo Chat
  services. Consider policy updates to allow these services.
- If you use reverse proxies, such as Apache, you might see GitLab Duo Chat connection issues in your logs, like **WebSocket connection to .... failures**.

To resolve this problem, try editing your Apache proxy settings:

```apache
# Enable WebSocket reverse Proxy
# Needs proxy_wstunnel enabled
  RewriteCond %{HTTP:Upgrade} websocket [NC]
  RewriteCond %{HTTP:Connection} upgrade [NC]
  RewriteRule ^/?(.*) "ws://127.0.0.1:8181/$1" [P,L]
```

## Run a health check for GitLab Duo

DETAILS:
**Offering:** Self-managed, GitLab Dedicated
**Tier:** Premium, Ultimate
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997) in GitLab 17.3.
> - [Download health check report added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165032) in GitLab 17.5.

Run a health check to test if your instance meets the requirements to use GitLab Duo.
When the health check completes, it displays a pass or fail result and the types of issues.
If the health check fails any of the tests, users might not be able to use GitLab Duo features in your instance.

This is a [beta](../../policy/experiment-beta-support.md) feature.

Prerequisites:

- You must be an administrator.

To run a health check:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. On the upper-right corner, select **Run health check**.
1. Optional. In GitLab 17.5 and later, after the health check is complete, you can select **Download report** to save a detailed report of the health check results.

### Health check tests

To verify if your instance meets the requirements to use GitLab Duo, the health check performs tests
for online and offline environments.

#### For online environments

| Test | Description |
|-----------------|-------------|
| Network | Tests whether your instance can connect to `customers.gitlab.com` and `cloud.gitlab.com`.<br><br>If your instance cannot connect to either destination, ensure that your firewall or proxy server settings [allow connection](#configure-gitlab-duo-on-a-self-managed-instance). |
| Synchronization | Tests whether your subscription: <br>- Has been activated with an activation code and can be synchronized with `customers.gitlab.com`.<br>- Has correct access credentials.<br>- Has been synchronized recently. If it hasn't or the access credentials are missing or expired, you can [manually synchronize](../../subscriptions/self_managed/index.md#manually-synchronize-subscription-data) your subscription data. |
| System exchange | Tests whether Code Suggestions can be used in your instance. If the system exchange assessment fails, users might not be able to use GitLab Duo features. |

#### For offline environments

| Test | Description |
|-----------------|-------------|
| Network | Tests whether: <br>- The environment variable `AI_GATEWAY_URL` has been set to a valid URL.<br> - Your instance can connect to the URL specified by `AI_GATEWAY_URL`.<br><br>If your instance cannot connect to the URL, ensure that your firewall or proxy server settings [allow connection](#configure-gitlab-duo-on-a-self-managed-instance). |
| License | Tests whether your license has the ability to access Code Suggestions feature. |
| System exchange | Tests whether Code Suggestions can be used in your instance. If the system exchange assessment fails, users might not be able to use GitLab Duo features. |

## Turn off GitLab Duo features

You can turn off GitLab Duo for a group, project, or instance.

When GitLab Duo is turned off for a group, project, or instance:

- GitLab Duo features that access resources, like code, issues, and vulnerabilities, are not available.
- Code Suggestions is not available.
- Duo Chat is not available.

### Turn off for a group

::Tabs

:::TabTitle In 17.4 and later

In GitLab 17.4 and later, follow these instructions to turn off GitLab Duo
for a group and its subgroups and projects.

Prerequisites:

- You must have the Owner role for the group.

To turn off GitLab Duo for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **GitLab Duo features**.
1. Choose an option:
   - To turn off GitLab Duo for the group, but let other groups or projects turn it on, select **Off by default**.
   - To turn off GitLab Duo for the group, and to prevent other groups or projects from turning it on, select **Never on**.
1. Select **Save changes**.

:::TabTitle In 17.3 and earlier

In GitLab 17.3 and earlier, follow these instructions to turn off GitLab Duo for a group
and its subgroups and projects.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Clear the **Use GitLab Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade the setting to
   all subgroups.

   ![Cascading setting](img/disable_duo_features_v17_1.png)

::EndTabs

### Turn off for a project

::Tabs

:::TabTitle In 17.4 and later

In GitLab 17.4 and later, follow these instructions to turn off GitLab Duo for a project.

Prerequisites:

- You must have the Owner role for the project.

To turn off GitLab Duo for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Under **GitLab Duo**, turn the toggle off.
1. Select **Save changes**.

:::TabTitle In 17.3 and earlier

In GitLab 17.3 and earlier, follow these instructions to turn off GitLab Duo for a project.

1. Use the GitLab GraphQL API
   [`projectSettingsUpdate`](../../api/graphql/reference/index.md#mutationprojectsettingsupdate)
   mutation.
1. Set the
   [`duo_features_enabled`](../../api/graphql/getting_started.md#update-project-settings)
   setting to `false`. (The default is `true`.)

::EndTabs

### Turn off for an instance

DETAILS:
**Offering:** Self-managed

::Tabs

:::TabTitle In 17.4 and later

In GitLab 17.4 and later, follow these instructions to turn off GitLab Duo for the instance.

Prerequisites:

- You must be an administrator.

To turn off GitLab Duo for an instance:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **GitLab Duo features**.
1. Choose an option:
   - To turn off GitLab Duo for the instance, but let groups and projects turn it on, select **Off by default**.
   - To turn off GitLab Duo for the instance, and to prevent groups or projects from ever turning it on, select **Never on**.
1. Select **Save changes**.

:::TabTitle In 17.3 and earlier

In GitLab 17.3 and earlier, follow these instructions to turn off GitLab Duo for an instance.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**
1. Expand **AI-powered features**.
1. Clear the **Use Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade
   the setting to all groups in the instance.

::EndTabs

NOTE:
An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/441532) to allow administrators
to override the setting for specific groups or projects.

## Turn on beta and experimental features

GitLab Duo features that are experimental and beta are turned off by default.
These features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

### On GitLab.com

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed

::Tabs

:::TabTitle In 17.4 and later

In GitLab 17.4 and later, follow these instructions to
turn on GitLab Duo experimental and beta features for your group on GitLab.com.

Prerequisites:

- You must have the Owner role for the top-level group.

To turn on GitLab Duo experiment and beta features for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **GitLab Duo features**.
1. Under **GitLab Duo preview features**, select **Use experiment and beta GitLab Duo features**.
1. Select **Save changes**.

:::TabTitle In 17.3 and earlier

In GitLab 17.3 and earlier, follow these instructions to
turn on GitLab Duo experimental and beta features for your group on GitLab.com.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **GitLab Duo experiment and beta features**, select the **Use experiment and beta GitLab Duo features** checkbox.
1. Select **Save changes**.

::EndTabs

This setting [cascades to all projects](../../user/project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
that belong to the group.

### On self-managed

::Tabs

:::TabTitle In 17.4 and later

In GitLab 17.4 and later, follow these instructions to turn on GitLab Duo
experiment and beta features for your self-managed instance.

Prerequisites:

- You must be an administrator.

To turn on GitLab Duo experiment and beta features for an instance:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **GitLab Duo features**.
1. Under **GitLab Duo preview features**, select **Use experiment and beta GitLab Duo features**.
1. Select **Save changes**.

:::TabTitle In 17.3 and earlier

To enable GitLab Duo beta and experimental features for GitLab versions
where GitLab Duo Chat is not yet generally available, see the
[GitLab Duo Chat documentation](../gitlab_duo_chat/turn_on_off.md#for-self-managed).

::EndTabs

## Troubleshooting

### GitLab Duo features do not work on self-managed

In addition to [turning on GitLab Duo features](turn_on_off.md#prerequisites),
you can also do the following:

1. As administrator, [run a health check for GitLab Duo](#run-a-health-check-for-gitlab-duo).

   ::Tabs

   :::TabTitle In 17.5 and later

   In GitLab 17.5 and later, you can use the UI to run health checks and download a detailed report that helps identify and troubleshoot issues.

   :::TabTitle In 17.4

   In GitLab 17.4, you can run the health check Rake task to generate a detailed report that helps identify and troubleshoot issues.

   ```shell
   sudo gitlab-rails 'cloud_connector:health_check(root,report.json)'
   ```

   :::TabTitle In 17.3 and earlier

   In GitLab 17.3 and earlier, you can download and run the `health_check` script to generate a detailed report that helps identify and troubleshoot issues.

   1. Download the health check script:

      ```shell
      wget https://gitlab.com/gitlab-org/gitlab/-/snippets/3734617/raw/main/health_check.rb
      ```

   1. Run the script using Rails Runner:

      ```shell
      gitlab-rails runner [full_path/to/health_check.rb] --debug --username [username] --output-file [report.txt]
      ```

       ```shell
       Usage: gitlab-rails runner full_path/to/health_check.rb
              --debug                Enable debug mode
              --output-file FILE     Write a report to FILE
              --username USERNAME    Provide a username to test seat assignments
              --skip [CHECK]         Skip specific check (options: access_data, token, license, host, features, end_to_end)
       ```

   ::EndTabs

1. Verify that the GitLab instance can reach the [required GitLab.com endpoints](#configure-gitlab-duo-on-a-self-managed-instance).
   You can use command-line tools such as `curl` to verify the connectivity.

    ```shell
    curl --verbose "https://cloud.gitlab.com"

    curl --verbose "https://customers.gitlab.com"
    ```

    If an HTTP/S proxy is configured for the GitLab instance, include the `proxy` parameter in the `curl` command.

    ```shell
    # https proxy for curl
    curl --verbose --proxy "http://USERNAME:PASSWORD@example.com:8080" "https://cloud.gitlab.com"
    curl --verbose --proxy "http://USERNAME:PASSWORD@example.com:8080" "https://customers.gitlab.com"
    ```

1. Optional. If you are using a [proxy server](#allow-outbound-connections-from-the-gitlab-instance) between the GitLab
   application and the public internet,
   [disable DNS rebinding protection](../../security/webhooks.md#enforce-dns-rebinding-attack-protection).

1. [Manually synchronize subscription data](../../subscriptions/self_managed/index.md#manually-synchronize-subscription-data).
   - Verify that the GitLab instance [synchronizes your subscription data with GitLab](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/).

### GitLab Duo features not available for users

In addition to [turning on GitLab Duo features](turn_on_off.md#prerequisites),
you can also do the following:

1. Verify that [subscription seats have been purchased](../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo-seats).
1. Ensure that [seats are assigned to users](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
1. For IDE users with the [GitLab Duo extension](../../user/project/repository/code_suggestions/supported_extensions.md#supported-editor-extensions):
   - Verify that the extension is up-to-date.
   - Run extension setting health checks, and test the authentication.
