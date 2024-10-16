---
stage: Govern
group: Authentication
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Project access tokens

> - [Became available in trial subscriptions](https://gitlab.com/gitlab-org/gitlab/-/issues/386041) in GitLab 16.1. Default prefix added.

Project access tokens are similar to passwords, except you can [limit access to resources](#scopes-for-a-project-access-token),
select a limited role, and provide an expiry date.

Use a project access token to authenticate:

- With the [GitLab API](../../../api/rest/index.md#personalprojectgroup-access-tokens).
- With Git, when using HTTP Basic Authentication, use:
  - Any non-blank value as a username.
  - The project access token as the password.

Project access tokens are similar to [group access tokens](../../group/settings/group_access_tokens.md)
and [personal access tokens](../../profile/personal_access_tokens.md), but project access tokens are scoped to a project, so you cannot use them to access resources from other projects.

In self-managed instances, project access tokens are subject to the same [maximum lifetime limits](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens) as personal access tokens if the limit is set.

WARNING:
The ability to create project access tokens without expiry was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369122) in GitLab 15.4 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0. In GitLab 16.0 and later, existing project access tokens without an expiry date are automatically given an expiry date of 365 days later than the current date. The automatic adding of an expiry date occurs on GitLab.com during the 16.0 milestone. The automatic adding of an expiry date occurs on self-managed instances when they are upgraded to GitLab 16.0. This change is a breaking change.

You can use project access tokens:

- On GitLab SaaS: If you have the Premium or Ultimate license tier, only one project access token is available with a [trial license](https://about.gitlab.com/free-trial/).
- On self-managed instances of GitLab: With any license tier. If you have the Free tier,
  consider [disabling project access tokens](#enable-or-disable-project-access-token-creation) to lower potential abuse.

You cannot use project access tokens to create other group, project, or personal access tokens.

Project access tokens inherit the [default prefix setting](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)
configured for personal access tokens.

## Create a project access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89114) in GitLab 15.1, Owners can select Owner role for project access tokens.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348660) in GitLab 15.3, default expiration of 30 days and default role of Guest is populated in the UI.
> - Ability to create non-expiring project access tokens [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0.

WARNING:
Project access tokens are treated as [internal users](../../../development/internal_users.md).
If an internal user creates a project access token, that token is able to access
all projects that have visibility level set to [Internal](../../public_access.md).

To create a project access token:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Access Tokens**.
1. Select **Add new token**.
1. Enter a name. The token name is visible to any user with permissions to view the project.
1. Enter an expiry date for the token.
   - The token expires on that date at midnight UTC.
   - If you do not enter an expiry date, the expiry date is automatically set to 30 days later than the current date.
   - By default, this date can be a maximum of 365 days later than the current date.
   - An instance-wide [maximum lifetime](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens) setting can limit the maximum allowable lifetime in self-managed instances.
1. Select a role for the token.
1. Select the [desired scopes](#scopes-for-a-project-access-token).
1. Select **Create project access token**.

A project access token is displayed. Save the project access token somewhere safe. After you leave or refresh the page, you can't view it again.

## Revoke a project access token

To revoke a project access token:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Access Tokens**.
1. Next to the project access token to revoke, select **Revoke** (**{remove}**).

## Scopes for a project access token

> - `k8s_proxy` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422408) in GitLab 16.4 [with a flag](../../../administration/feature_flags.md) named `k8s_proxy_pat`. Enabled by default.
> - Feature flag `k8s_proxy_pat` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518) in GitLab 16.5.

The scope determines the actions you can perform when you authenticate with a project access token.

NOTE:
See the warning in [create a project access token](#create-a-project-access-token) regarding internal projects.

| Scope              | Description                                                                                                                                                                                                                                                                              |
|:-------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | Grants complete read and write access to the scoped project API, including the [container registry](../../packages/container_registry/index.md), the [dependency proxy](../../packages/dependency_proxy/index.md), and the [package registry](../../packages/package_registry/index.md). |
| `read_api`         | Grants read access to the scoped project API, including the [package registry](../../packages/package_registry/index.md).                                                                                                                                                                |
| `read_registry`    | Grants read access (pull) to the [container registry](../../packages/container_registry/index.md) images if a project is private and authorization is required.                                                                                                                          |
| `write_registry`   | Grants write access (push) to the [container registry](../../packages/container_registry/index.md). You need both read and write access to push images.                                                                                                                              |
| `read_repository`  | Grants read access (pull) to the repository.                                                                                                                                                                                                                                             |
| `write_repository` | Grants read and write access (pull and push) to the repository.                                                                                                                                                                                                                          |
| `create_runner`    | Grants permission to create runners in the project.                                                                                                                                                                                                                                      |
| `manage_runner`    | Grants permission to manage runners in the project.                                                                                                                                                                                                                                      |
| `ai_features`      | Grants permission to perform API actions for GitLab Duo. This scope is designed to work with the GitLab Duo Plugin for JetBrains. For all other extensions, see scope requirements.                                                                                                          |
| `k8s_proxy`        | Grants permission to perform Kubernetes API calls using the agent for Kubernetes in the project.                                                                                                                                                                                         |

## Enable or disable project access token creation

To enable or disable project access token creation for all projects in a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. In **Permissions**, select or clear the **Users can create project access tokens and group access tokens in this group** checkbox.

Even when creation is disabled, you can still use and revoke existing project access tokens.

## Bot users for projects

Bot users for projects are [GitLab-created service accounts](../../../subscriptions/self_managed/index.md#billable-users).
Each time you create a project access token, a bot user is created and added to the project.
This user is not a billable user, so it does not count toward the license limit.

The bot users for projects have [permissions](../../permissions.md#project-members-permissions) that correspond with the
selected role and [scope](#scopes-for-a-project-access-token) of the project access token.

- The name is set to the name of the token.
- The username is set to `project_{project_id}_bot_{random_string}`. For example, `project_123_bot_4ffca233d8298ea1`.
- The email is set to `project_{project_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`. For example, `project_123_bot_4ffca233d8298ea1@noreply.example.com`.

API calls made with a project access token are associated with the corresponding bot user.

Bot users for projects:

- Are included in a project's member list but cannot be modified.
- Cannot be added to any other project.
- Can have a maximum role of Owner for a project. For more information, see
  [Create a project access token](../../../api/project_access_tokens.md#create-a-project-access-token).

When the project access token is [revoked](#revoke-a-project-access-token):

- The bot user is deleted.
- All records are moved to a system-wide user with the username [Ghost User](../../profile/account/delete_account.md#associated-records).

See also [Bot users for groups](../../group/settings/group_access_tokens.md#bot-users-for-groups).

## Token availability

More than one project access token is only available in paid subscriptions. In Premium and Ultimate trial subscriptions, only one project access token is included. For more information, see the ["What is included" section of the GitLab Trial FAQ](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded).
