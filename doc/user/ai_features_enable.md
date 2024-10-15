---
stage: AI-powered
group: AI Model Validation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Control GitLab Duo availability

> - [Settings to turn off AI features introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10.
> - [Settings to turn off AI features added to the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) in GitLab 16.11.

GitLab Duo features that are Generally Available are automatically turned on for all users that have access.
In addition:

- If you have self-managed GitLab, you must
  [allow connectivity](#configure-gitlab-duo-on-a-self-managed-instance).
- If you have GitLab Dedicated, you must have [GitLab Duo Pro or Enterprise](../subscriptions/subscription-add-ons.md).
- For some Generally Available features, like [Code Suggestions](project/repository/code_suggestions/index.md),
  [you must assign seats](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-pro-seats)
  to the users you want to have access.

GitLab Duo features that are Experiment or Beta are turned off by default
and [must be turned on](#turn-on-beta-and-experimental-features).

## Configure GitLab Duo on a self-managed instance

To use GitLab Duo on a self-managed instance, you must ensure connectivity exists.

### Allow outbound connections from the GitLab instance

- Your firewalls and HTTP/S proxy servers must allow outbound connections
  to `cloud.gitlab.com` and `customers.gitlab.com` on port `443` both with `https://`.
- To use an HTTP/S proxy, both `gitLab_workhorse` and `gitLab_rails` must have the necessary
  [web proxy environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html) set.

### Allow inbound connections from clients to the GitLab instance

- GitLab instances must allow inbound connections from Duo clients (IDEs, Code Editors, and GitLab Web Frontend)
  on port 443 with `https://` and `wss://`.
- Both `HTTP2` and the `'upgrade'` header must be allowed, because GitLab Duo
  uses both REST and WebSockets.
- Check for restrictions on WebSocket (`wss://`) traffic to `wss://gitlab.example.com/-/cable` and other `.com` domains.
  Network policy restrictions on `wss://` traffic can cause issues with some GitLab Duo Chat
  services. Consider policy updates to allow these services.

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

<!-- vale gitlab.Substitutions = NO -->
1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Clear the **Use Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade the setting to
   all subgroups.

   ![Cascading setting](img/disable_duo_features_v17_0.png)
<!-- vale gitlab.Substitutions = YES -->

NOTE:
An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/448709) for making the group-level
setting cascade to all groups and projects. Right now the lower-level projects and groups do not
display the setting of the top-level group.

### Turn off for a project

You can turn off GitLab Duo for a project.

Prerequisites:

- You must have the Owner role for the project.

To turn off GitLab Duo for a project:

1. Use the [GitLab GraphQL API](../api/graphql/getting_started.md)
   `projectSettingsUpdate` mutation.
1. Turn off GitLab Duo for the project by setting the `duo_features_enabled` setting to `false`.
   (The default is `true`.)

### Turn off for an instance

DETAILS:
**Offering:** Self-managed

You can turn off GitLab Duo for the instance.

Prerequisites:

- You must be an administrator.

To turn off GitLab Duo for an instance:

<!-- vale gitlab.Substitutions = NO -->
1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**
1. Expand **AI-powered features**.
1. Clear the **Use Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade
   the setting to all groups in the instance.
<!-- vale gitlab.Substitutions = YES -->

NOTE:
An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/441532) to allow administrators
to override the setting for specific groups or projects.

## Turn on Beta and Experimental features

Features listed as Experiment and Beta are turned off by default.
These features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

### On GitLab.com

You can turn on Experiment and Beta features for your group on GitLab.com.

Prerequisites:

- You must have the Owner role in the top-level group.

To turn on Beta and Experimental GitLab Duo features, use the [Experiment and Beta features checkbox](group/manage.md#enable-experiment-and-beta-features).

### On self-managed

To enable Beta and Experimental GitLab Duo features for GitLab versions where GitLab Duo Chat is not yet generally available, see the [GitLab Duo Chat documentation](gitlab_duo_chat_enable.md#for-self-managed).
