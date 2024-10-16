---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Deploy keys

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Use deploy keys to access repositories that are hosted in GitLab. In most cases, you use deploy keys
to access a repository from an external host, like a build server or Continuous Integration (CI) server.

Depending on your needs, you might want to use a [deploy token](../deploy_tokens/index.md) to access a repository instead.

| Attribute        |  Deploy key | Deploy token |
|------------------|-------------|--------------|
| Sharing          | Shareable between multiple projects, even those in different groups. | Belong to a project or group. |
| Source           | Public SSH key generated on an external host. | Generated on your GitLab instance, and is provided to users only at creation time. |
| Accessible resources  | Git repository over SSH | Git repository over HTTP, package registry, and container registry. |

Deploy keys can't be used for Git operations if [external authorization](../../../administration/settings/external_authorization.md) is enabled.

## Scope

A deploy key has a defined scope when it is created:

- **Project deploy key:** Access is limited to the selected project.
- **Public deploy key:** Access can be granted to _any_ project in a GitLab instance. Access to each
  project must be [granted](#grant-project-access-to-a-public-deploy-key) by a user with at least
  the Maintainer role.

You cannot change a deploy key's scope after creating it.

## Permissions

A deploy key is given a permission level when it is created:

- **Read-only:** A read-only deploy key can only read from the repository.
- **Read-write:** A read-write deploy key can read from, and write to, the repository.

You can change a deploy key's permission level after creating it. Changing a project deploy key's
permissions only applies for the current project.

GitLab authorizes the creator of the deploy key if the Git-command triggers additional processes. For example:

- When a deploy key is used to push a commit to a [protected branch](../protected_branches.md),
  the _creator_ of the deploy key must have access to the branch.
- When a deploy key is used to push a commit that triggers a CI/CD pipeline, the _creator_ of the
  deploy key must have access to the CI/CD resources, including protected environments and secret
  variables.

## Security implications

The intended use case for deploy keys is for non-human interaction with GitLab, for example: an automated script running on a server in your organization.

You should create a dedicated account to act as a service account, and create the deploy key with the service account.
If you use another user account to create deploy keys, the user is granted persistent privileges.

In addition:

- Deploy keys work even if the user who created them is removed from the group or project.
- The creator of a deploy key retains access to the group or project, even if the user is demoted or removed.
- When a deploy key is specified in a protected branch rule, the creator of the deploy key gains access to the protected branch, as well as to the deploy key itself.

As with all sensitive information, you should ensure only those who need access to the secret can read it.
For human interactions, use credentials tied to users such as Personal Access Tokens.

To help detect a potential secret leak, you can use the
[Audit Event](../../compliance/audit_event_schema.md#example-audit-event-payloads-for-git-over-ssh-events-with-deploy-key) feature.

## View deploy keys

To view the deploy keys available to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Deploy keys**.

The deploy keys available are listed:

- **Enabled deploy keys:** Deploy keys that have access to the project.
- **Privately accessible deploy keys:** Project deploy keys that don't have access to the project.
- **Public accessible deploy keys:** Public deploy keys that don't have access to the project.

## Create a project deploy key

Prerequisites:

- You must have at least the Maintainer role for the project.
- [Generate an SSH key pair](../../ssh.md#generate-an-ssh-key-pair). Put the private SSH
  key on the host that requires access to the repository.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Deploy keys**.
1. Select **Add new key**.
1. Complete the fields.
1. Optional. To grant `read-write` permission, select the **Grant write permissions to this key**
   checkbox.
1. Optional. Update the **Expiration date**.

A project deploy key is enabled when it is created. You can modify only a project deploy key's
name and permissions. If the deploy key is enabled in more than one project, you can't modify the deploy key name.

## Create a public deploy key

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

Prerequisites:

- You must have administrator access to the instance.
- You must [generate an SSH key pair](../../ssh.md#generate-an-ssh-key-pair).
- You must put the private SSH key on the host that requires access to the repository.

To create a public deploy key:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Deploy Keys**.
1. Select **New deploy key**.
1. Complete the fields.
   - Use a meaningful description for **Name**. For example, include the name of the external host
     or application that uses the public deploy key.

You can modify only a public deploy key's name.

## Grant project access to a public deploy key

Prerequisites:

- You must have at least the Maintainer role for the project.

To grant a public deploy key access to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Deploy keys**.
1. Select **Publicly accessible deploy keys**.
1. In the key's row, select **Enable**.
1. To grant read-write permission to the public deploy key:
   1. In the key's row, select **Edit** (**{pencil}**).
   1. Select the **Grant write permissions to this key** checkbox.

### Edit project access permissions of a deploy key

Prerequisites:

- You must have at least the Maintainer role for the project.

To edit the project access permissions of a deploy key:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Deploy keys**.
1. In the key's row, select **Edit** (**{pencil}**).
1. Select or clear the **Grant write permissions to this key** checkbox.

## Revoke project access of a deploy key

To revoke a deploy key's access to a project, you can disable it. Any service that relies on
a deploy key stops working when the key is disabled.

Prerequisites:

- You must have at least the Maintainer role for the project.

To disable a deploy key:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Deploy keys**.
1. Select **Disable** (**{cancel}**).

What happens to the deploy key when it is disabled depends on the following:

- If the key is publicly accessible, it is removed from the project but still available in the
  **Publicly accessible deploy keys** tab.
- If the key is privately accessible and only in use by this project, it is deleted.
- If the key is privately accessible and also in use by other projects, it is removed from the
  project, but still available in the **Privately accessible deploy keys** tab.

## Troubleshooting

### Deploy key cannot push to a protected branch

There are a few scenarios where a deploy key fails to push to a
[protected branch](../protected_branches.md).

- The owner associated to a deploy key does not have [membership](../members/index.md) to the project of the protected branch.
- The owner associated to a deploy key has [project membership permissions](../../../user/permissions.md#project-members-permissions) lower than required to **View project code**.
- The deploy key does not have [read-write permissions for the project](#edit-project-access-permissions-of-a-deploy-key).
- The deploy key has been [revoked](#revoke-project-access-of-a-deploy-key).
- **No one** is selected in [the **Allowed to push and merge** section](../protected_branches.md#add-protection-to-existing-branches) of the protected branch.

All deploy keys are associated to an account. Since the permissions for an account can change, this might lead to scenarios where a deploy key that was working is suddenly unable to push to a protected branch.

We recommend you create a service account, and associate a deploy key to the service account, for projects using deploy keys.

#### Identify deploy keys associated with non-member and blocked users

If you need to find the keys that belong to a non-member or blocked user,
you can use [the Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session) to identify unusable deploy keys using a script similar to the following:

```ruby
ghost_user_id = Users::Internal.ghost.id

DeployKeysProject.with_write_access.find_each do |deploy_key_mapping|
  project = deploy_key_mapping.project
  deploy_key = deploy_key_mapping.deploy_key
  user = deploy_key.user

  access_checker = Gitlab::DeployKeyAccess.new(deploy_key, container: project)

  # can_push_for_ref? tests if deploy_key can push to default branch, which is likely to be protected
  can_push = access_checker.can_do_action?(:push_code)
  can_push_to_default = access_checker.can_push_for_ref?(project.repository.root_ref)

  next if access_checker.allowed? && can_push && can_push_to_default

  if user.nil? || user.id == ghost_user_id
    username = 'none'
    state = '-'
  else
    username = user.username
    user_state = user.state
  end

  puts "Deploy key: #{deploy_key.id}, Project: #{project.full_path}, Can push?: " + (can_push ? 'YES' : 'NO') +
       ", Can push to default branch #{project.repository.root_ref}?: " + (can_push_to_default ? 'YES' : 'NO') +
       ", User: #{username}, User state: #{user_state}"
end
```
