---
description: "Internal users documentation."
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Internal users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97584) in GitLab 15.4, bots are indicated with a badge in user listings.

GitLab uses internal users (sometimes referred to as "bots") to perform
actions or functions that cannot be attributed to a regular user.

These users are created programmatically throughout the codebase itself when
necessary, and do not count towards a license limit.

They are used when a traditional user account would not be applicable, for
example when generating alerts or automatic review feedback.

Technically, an internal user is a type of user, but they have reduced access
and a very specific purpose. They cannot be used for regular user actions,
such as authentication or API requests.

They have email addresses and names which can be attributed to any actions
they perform.

For example, when we [migrated](https://gitlab.com/gitlab-org/gitlab/-/issues/216120)
GitLab Snippets to [Versioned Snippets](../user/snippets.md#versioned-snippets)
we used an internal user to attribute the authorship of
snippets to itself when a snippet's author wasn't available for creating
repository commits, such as when the user has been disabled, so the Migration
Bot was used instead.

For this bot:

- The name was set to `GitLab Migration Bot`.
- The email was set to `noreply+gitlab-migration-bot@{instance host}`.

Other examples of internal users:

- [GitLab Admin Bot](https://gitlab.com/gitlab-org/gitlab/-/blob/278bc9018dd1515a10cbf15b6c6cd55cb5431407/app/models/user.rb#L950-960)
- [Alert Bot](../operations/incident_management/alerts.md#trigger-actions-from-alerts)
- [Ghost User](../user/profile/account/delete_account.md#associated-records)
- [Support Bot](../user/project/service_desk/configure.md#support-bot-user)
- Visual Review Bot
- Resource access tokens, including:
  - [Project access tokens](../user/project/settings/project_access_tokens.md).
  - [Group access tokens](../user/group/settings/group_access_tokens.md).

  These are implemented as `project_{project_id}_bot_{random_string}` i.e. `group_{group_id}_bot_{random_string}` users, with a `PersonalAccessToken`.
