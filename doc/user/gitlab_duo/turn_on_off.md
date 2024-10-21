---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Control GitLab Duo availability

> - [Settings to turn off AI features introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10.
> - [Settings to turn off AI features added to the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) in GitLab 16.11.

GitLab Duo features that are generally available are automatically turned on for all users that have access.
In addition:

- If you have self-managed GitLab:
  - You must [allow connectivity](#configure-gitlab-duo-on-a-self-managed-instance).
  - You must [activate your instance with a cloud license](../../administration/license.md#activate-gitlab-ee).
  - For the best experience, you should upgrade to the [latest version of GitLab](https://about.gitlab.com/releases/categories/releases/).
- If you have GitLab Dedicated, you must have [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md).
- For some generally available features, like [Code Suggestions](../project/repository/code_suggestions/index.md),
  [you must assign seats](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-pro-seats)
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

- GitLab instances must allow inbound connections from Duo clients (IDEs, Code Editors, and GitLab Web Frontend)
  on port 443 with `https://` and `wss://`.
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

Run a health check to test if your instance meets the requirements to use GitLab Duo.
When the health check completes, it displays a pass or fail result and the types of issues.

This is a [beta](../../policy/experiment-beta-support.md) feature.

Prerequisites:

- You must be an administrator.

To run a health check:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. On the upper-right corner, select **Run health check**.

## Turn off GitLab Duo features

You can turn off GitLab Duo for a group, project, or instance.

When GitLab Duo is turned off for a group, project, or instance:

- GitLab Duo features that access resources, like code, issues, and vulnerabilities, are not available.
- Code Suggestions are not available.

However, GitLab Duo Chat works differently. When you turn off GitLab Duo:

- For a group or project:
  - You can still ask questions of GitLab Duo Chat. These questions must be generic, like
    asking about GitLab or asking general questions about code. GitLab Duo Chat will not access group or
    project resources, and will reject questions about them.

- For an instance:
  - The **GitLab Duo Chat** button is not available anywhere in the UI.

### Turn off for a group

You can turn off GitLab Duo for a group.

Prerequisites:

- You must have the Owner role for the group or project.

To turn off GitLab Duo for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Clear the **Use GitLab Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade the setting to
   all subgroups.

   ![Cascading setting](img/disable_duo_features_v17_1.png)

### Turn off for a project

You can turn off GitLab Duo for a project.

Prerequisites:

- You must have the Owner role for the project.

To turn off GitLab Duo for a project:

1. Use the GitLab GraphQL API
   [`projectSettingsUpdate`](../../api/graphql/reference/index.md#mutationprojectsettingsupdate)
   mutation.
1. Set the
   [`duo_features_enabled`](../../api/graphql/getting_started.md#update-project-settings)
   setting to `false`. (The default is `true`.)

### Turn off for an instance

DETAILS:
**Offering:** Self-managed

You can turn off GitLab Duo for the instance.

Prerequisites:

- You must be an administrator.

To turn off GitLab Duo for an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**
1. Expand **AI-powered features**.
1. Clear the **Use Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade
   the setting to all groups in the instance.

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118222) in GitLab 16.0.
> - [Added to GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147833) in GitLab 16.11.

You can turn on GitLab Duo experiment and beta features for your group on GitLab.com.

Prerequisites:

- You must have the Owner role in the top-level group.

To turn on GitLab Duo experiment and beta features for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **GitLab Duo experiment and beta features**, select the **Use experiment and beta Duo features** checkbox.
1. Select **Save changes**.

This setting [cascades to all projects](../../user/project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
that belong to the group.

### On self-managed

To enable GitLab Duo beta and experimental features for GitLab versions
where GitLab Duo Chat is not yet generally available, see the
[GitLab Duo Chat documentation](../gitlab_duo_chat/turn_on_off.md#for-self-managed).
