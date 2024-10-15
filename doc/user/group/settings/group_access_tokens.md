---
stage: Govern
group: Authentication
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Group access tokens

DETAILS:
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

With group access tokens, you can use a single token to:

- Perform actions for groups.
- Manage the projects within the group.

You can use a group access token to authenticate:

- With the [GitLab API](../../../api/rest/index.md#personalprojectgroup-access-tokens).
- Authenticate with Git over HTTPS.
  Use:

  - Any non-blank value as a username.
  - The group access token as the password.

> On GitLab.com, you can use group access tokens if you have the Premium or Ultimate license tier. Group access tokens are not available with a [trial license](https://about.gitlab.com/free-trial/).
>
> On GitLab Dedicated and self-managed instances, you can use group access tokens with any license tier. If you have the Free tier:
>
> - Review your security and compliance policies around [user self-enrollment](../../../administration/settings/sign_up_restrictions.md#disable-new-sign-ups).
> - Consider [disabling group access tokens](#enable-or-disable-group-access-token-creation) to lower potential abuse.

Group access tokens are similar to [project access tokens](../../project/settings/project_access_tokens.md)
and [personal access tokens](../../profile/personal_access_tokens.md), except they are
associated with a group rather than a project or user.

In self-managed instances, group access tokens are subject to the same [maximum lifetime limits](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens) as personal access tokens if the limit is set.

WARNING:
The ability to create group access tokens without an expiry date was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369122) in GitLab 15.4 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0. In GitLab 16.0 and later, existing group access tokens without an expiry date are automatically given an expiry date 365 days later than the current date. The automatic adding of an expiry date occurs on GitLab.com during the 16.0 milestone. The automatic adding of an expiry date occurs on self-managed instances when they are upgraded to GitLab 16.0. This change is a breaking change.

You cannot use group access tokens to create other group, project, or personal access tokens.

Group access tokens inherit the [default prefix setting](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)
configured for personal access tokens.

## Create a group access token using UI

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348660) in GitLab 15.3, default expiration of 30 days and default role of Guest is populated in the UI.
> - Ability to create non-expiring group access tokens [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392855) in GitLab 16.0.

WARNING:
Project access tokens are treated as [internal users](../../../development/internal_users.md).
If an internal user creates a project access token, that token is able to access
all projects that have visibility level set to [Internal](../../public_access.md).

To create a group access token:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Access Tokens**.
1. Select **Add new token**.
1. Enter a name. The token name is visible to any user with permissions to view the group.
1. Enter an expiry date for the token:
   - The token expires on that date at midnight UTC.
   - If you do not enter an expiry date, the expiry date is automatically set to 365 days later than the current date.
   - By default, this date can be a maximum of 365 days later than the current date.
   - An instance-wide [maximum lifetime](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens) setting can limit the maximum allowable lifetime in self-managed instances.
1. Select a role for the token.
1. Select the [desired scopes](#scopes-for-a-group-access-token).
1. Select  **Create group access token**.

A group access token is displayed. Save the group access token somewhere safe. After you leave or refresh the page, you can't view it again.

## Create a group access token using Rails console

If you are an administrator, you can create group access tokens in the Rails console:

1. Run the following commands in a [Rails console](../../../administration/operations/rails_console.md):

   ```ruby
   # Set the GitLab administration user to use. If user ID 1 is not available or is not an administrator, use 'admin = User.admins.first' instead to select an administrator.
   admin = User.find(1)

   # Set the group you want to create a token for. For example, group with ID 109.
   group = Group.find(109)

   # Create the group bot user. For further group access tokens, the username should be `group_{group_id}_bot_{random_string}` and email address `group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`.
   random_string = SecureRandom.hex(16)
   bot = Users::CreateService.new(admin, { name: 'group_token', username: "group_#{group.id}_bot_#{random_string}", email: "group_#{group.id}_bot_#{random_string}@noreply.#{Gitlab.config.gitlab.host}", user_type: :project_bot }).execute

   # Confirm the group bot.
   bot.confirm

   # Add the bot to the group with the required role.
   group.add_member(bot, :maintainer)

   # Give the bot a personal access token.
   token = bot.personal_access_tokens.create(scopes:[:api, :write_repository], name: 'group_token')

   # Get the token value.
   gtoken = token.token
   ```

1. Test if the generated group access token works:

   1. Use the group access token in the `PRIVATE-TOKEN` header with GitLab REST APIs. For example:

      - [Create an epic](../../../api/epics.md#new-epic) in the group.
      - [Create a project pipeline](../../../api/pipelines.md#create-a-new-pipeline) in one of the group's projects.
      - [Create an issue](../../../api/issues.md#new-issue) in one of the group's projects.

   1. Use the group token to [clone a group's project](../../../topics/git/clone.md#clone-with-https)
      using HTTPS.

## Revoke a group access token using the UI

To revoke a group access token:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Access Tokens**.
1. Next to the group access token to revoke, select **Revoke**  (**{remove}**).

## Revoke a group access token using Rails console

If you are a GitLab administrator, you can revoke a group access token.
Run this command in a [Rails console](../../../administration/operations/rails_console.md):

```ruby
bot = User.find_by(username: 'group_109_bot') # the owner of the token you want to revoke
token = bot.personal_access_tokens.last # the token you want to revoke
token.revoke!
```

## Scopes for a group access token

> - `k8s_proxy` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422408) in GitLab 16.4 [with a flag](../../../administration/feature_flags.md) named `k8s_proxy_pat`. Enabled by default.
> - Feature flag `k8s_proxy_pat` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518) in GitLab 16.5.

The scope determines the actions you can perform when you authenticate with a group access token.

| Scope              | Description                                                                                                                                                                                                                                                                                                |
|:-------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | Grants complete read and write access to the scoped group and related project API, including the [container registry](../../packages/container_registry/index.md), the [dependency proxy](../../packages/dependency_proxy/index.md), and the [package registry](../../packages/package_registry/index.md). |
| `read_api`         | Grants read access to the scoped group and related project API, including the [package registry](../../packages/package_registry/index.md).                                                                                                                                                                |
| `read_registry`    | Grants read access (pull) to the [container registry](../../packages/container_registry/index.md) images if any project within a group is private and authorization is required.                                                                                                                           |
| `write_registry`   | Grants write access (push) to the [container registry](../../packages/container_registry/index.md). You need both read and write access to push images.                                                                                                                                                |
| `read_repository`  | Grants read access (pull) to all repositories within a group.                                                                                                                                                                                                                                              |
| `write_repository` | Grants read and write access (pull and push) to all repositories within a group.                                                                                                                                                                                                                           |
| `create_runner`    | Grants permission to create runners in a group.                                                                                                                                                                                                                                                            |
| `ai_features`      | Grants permission to perform API actions for GitLab Duo. This scope is designed to work with the GitLab Duo Plugin for JetBrains. For all other extensions, see scope requirements.                                                                                                          |
| `k8s_proxy`        | Grants permission to perform Kubernetes API calls using the agent for Kubernetes in a group.                                                                                                                                                                                                               |

## Enable or disable group access token creation

To enable or disable group access token creation for all subgroups in a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Permissions**, turn on or off **Users can create project access tokens and group access tokens in this group**.
1. Select **Save changes**.

Even when creation is disabled, you can still use and revoke existing group access tokens.

## Bot users for groups

Bot users for groups are [GitLab-created service accounts](../../../subscriptions/self_managed/index.md#billable-users).
Each time you create a group access token, a bot user is created and added to the group.
These bot users are similar to
[bot users for projects](../../project/settings/project_access_tokens.md#bot-users-for-projects), except they are added
to groups instead of projects. Bot users for groups:

- Is not a billable user, so it does not count toward the license limit.
- Can have a maximum role of Owner for a group. For more information, see
  [Create a group access token](../../../api/group_access_tokens.md#create-a-group-access-token).
- Have a username set to `group_{group_id}_bot_{random_string}`. For example, `group_123_bot_4ffca233d8298ea1`.
- Have an email set to `group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`. For example, `group_123_bot_4ffca233d8298ea1@noreply.example.com`.

All other properties are similar to [bot users for projects](../../project/settings/project_access_tokens.md#bot-users-for-projects).

## Token availability

Group access tokens are only available in paid subscriptions, and not available in trial subscriptions. For more information, see the ["What is included" section of the GitLab Trial FAQ](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded).
