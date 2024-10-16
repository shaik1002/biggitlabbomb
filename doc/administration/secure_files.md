---
stage: Mobile
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secure Files administration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) in GitLab 15.7. Feature flag `ci_secure_files` removed.

You can securely store up to 100 files for use in CI/CD pipelines as secure files.
These files are stored securely outside of your project's repository and are not version controlled.
It is safe to store sensitive information in these files. Secure files support both plain text
and binary file types, and must be 5 MB or less.

The storage location of these files can be configured using the options described below,
but the default locations are:

- `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files` for installations using the Linux package.
- `/home/git/gitlab/shared/ci_secure_files` for self-compiled installations.

Use [external object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy)
configuration for [GitLab Helm chart](https://docs.gitlab.com/charts/) installations.

## Disabling Secure Files

You can disable Secure Files across the entire GitLab instance. You might want to disable
Secure Files to reduce disk space, or to remove access to the feature.

To disable Secure Files, follow the steps below according to your installation.

Prerequisites:

- You must be an administrator.

**For Linux package installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['ci_secure_files_enabled'] = false
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

**For self-compiled installations**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   ci_secure_files:
     enabled: false
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.

## Using local storage

The default configuration uses local storage. To change the location where Secure Files
are stored locally, follow the steps below.

**For Linux package installations**

1. To change the storage path for example to `/mnt/storage/ci_secure_files`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['ci_secure_files_storage_path'] = "/mnt/storage/ci_secure_files"
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

**For self-compiled installations**

1. To change the storage path for example to `/mnt/storage/ci_secure_files`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   ci_secure_files:
     enabled: true
     storage_path: /mnt/storage/ci_secure_files
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

## Using object storage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Instead of storing Secure Files on disk, you should use [one of the supported object storage options](object_storage.md#supported-object-storage-providers).
This configuration relies on valid credentials to be configured already.

[Read more about using object storage with GitLab](object_storage.md).

NOTE:
This feature is not supported by consolidated object storage configuration.
Adding support is proposed in [issue 414673](https://gitlab.com/gitlab-org/gitlab/-/issues/414673).

### Object storage settings

The following settings are:

- Nested under `ci_secure_files:` and then `object_store:` on self-compiled installations.
- Prefixed by `ci_secure_files_object_store_` on Linux package installations.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where Secure Files are stored | |
| `connection` | Various connection options described below | |

### S3-compatible connection settings

See [the available connection settings for different providers](object_storage.md#configure-the-connection-settings).

**For Linux package installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines, but using
   the values you want:

   ```ruby
   gitlab_rails['ci_secure_files_object_store_enabled'] = true
   gitlab_rails['ci_secure_files_object_store_remote_directory'] = "ci_secure_files"
   gitlab_rails['ci_secure_files_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   NOTE:
   If you are using AWS IAM profiles, be sure to omit the AWS access key and secret access key/value pairs:

   ```ruby
   gitlab_rails['ci_secure_files_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Migrate any existing local states to the object storage](#migrate-to-object-storage).

**For self-compiled installations**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   ci_secure_files:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "ci_secure_files"  # The bucket name
       connection:
         provider: AWS  # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.
1. [Migrate any existing local states to the object storage](#migrate-to-object-storage).

### Migrate to object storage

> - [Introduced](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/125) in GitLab 16.1.

WARNING:
It's not possible to migrate Secure Files from object storage back to local storage,
so proceed with caution.

To migrate Secure Files to object storage, follow the instructions below.

- For Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:ci_secure_files:migrate
  ```

- For self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake gitlab:ci_secure_files:migrate RAILS_ENV=production
  ```
