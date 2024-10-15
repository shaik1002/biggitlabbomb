---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting common Geo errors

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

## Basic troubleshooting

Before attempting more advanced troubleshooting:

- Check [the health of the Geo sites](#check-the-health-of-the-geo-sites).
- Check [if PostgreSQL replication is working](#check-if-postgresql-replication-is-working).

### Check the health of the Geo sites

On the **primary** site:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Geo > Sites**.

We perform the following health checks on each **secondary** site
to help identify if something is wrong:

- Is the site running?
- Is the secondary site's database configured for streaming replication?
- Is the secondary site's tracking database configured?
- Is the secondary site's tracking database connected?
- Is the secondary site's tracking database up-to-date?
- Is the secondary site's status less than 10 minutes old?

A site shows as "Unhealthy" if the site's status is more than 10 minutes old. In that case, try running the following in the [Rails console](../../../operations/rails_console.md) on the affected secondary site:

```ruby
Geo::MetricsUpdateWorker.new.perform
```

If it raises an error, then the error is probably also preventing the jobs from completing. If it takes longer than 10 minutes, then there may be a performance issue, and the UI may always show "Unhealthy" even if the status eventually does get updated.

If it successfully updates the status, then something may be wrong with Sidekiq. Is it running? Do the logs show errors? This job is supposed to be enqueued every minute and might not run if a [job deduplication idempotency](../../../sidekiq/sidekiq_troubleshooting.md#clearing-a-sidekiq-job-deduplication-idempotency-key) key was not cleared properly. It takes an exclusive lease in Redis to ensure that only one of these jobs can run at a time. The primary site updates its status directly in the PostgreSQL database. Secondary sites send an HTTP Post request to the primary site with their status data.

A site also shows as "Unhealthy" if certain health checks fail. You can reveal the failure by running the following in the [Rails console](../../../operations/rails_console.md) on the affected secondary site:

```ruby
Gitlab::Geo::HealthCheck.new.perform_checks
```

If it returns `""` (an empty string) or `"Healthy"`, then the checks succeeded. If it returns anything else, then the message should explain what failed, or show the exception message.

For information about how to resolve common error messages reported from the user interface,
see [Fixing Common Errors](#fixing-common-errors).

If the user interface is not working, or you are unable to sign in, you can run the Geo
health check manually to get this information and a few more details.

#### Health check Rake task

> - The use of a custom NTP server was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105514) in GitLab 15.7.

This Rake task can be run on a **Rails** node in the **primary** or **secondary**
Geo sites:

```shell
sudo gitlab-rake gitlab:geo:check
```

Example output:

```plaintext
Checking Geo ...

GitLab Geo is available ... yes
GitLab Geo is enabled ... yes
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
GitLab Geo tracking database is correctly configured ... yes
Database replication enabled? ... yes
Database replication working? ... yes
GitLab Geo HTTP(S) connectivity ...
* Can connect to the primary node ... yes
HTTP/HTTPS repository cloning is enabled ... yes
Machine clock is synchronized ... yes
Git user has default SSH configuration? ... yes
OpenSSH configured to use AuthorizedKeysCommand ... yes
GitLab configured to disable writing to authorized_keys file ... yes
GitLab configured to store new projects in hashed storage? ... yes
All projects are in hashed storage? ... yes

Checking Geo ... Finished
```

You can also specify a custom NTP server using environment variables. For example:

```shell
sudo gitlab-rake gitlab:geo:check NTP_HOST="ntp.ubuntu.com" NTP_TIMEOUT="30"
```

The following environment variables are supported.

| Variable    | Description | Default value |
| ----------- | ----------- | ------------- |
|`NTP_HOST`   | The NTP host. | `pool.ntp.org` |
|`NTP_PORT`   | The NTP port the host listens on. |`ntp`|
|`NTP_TIMEOUT`| The NTP timeout in seconds. | The value defined in the `net-ntp` Ruby library ([60 seconds](https://github.com/zencoder/net-ntp/blob/3d0990214f439a5127782e0f50faeaf2c8ca7023/lib/net/ntp/ntp.rb#L6)). |

If the Rake task skips the `OpenSSH configured to use AuthorizedKeysCommand` check, the
following output displays:

```plaintext
OpenSSH configured to use AuthorizedKeysCommand ... skipped
  Reason:
  Cannot access OpenSSH configuration file
  Try fixing it:
  This is expected if you are using SELinux. You may want to check configuration manually
  For more information see:
  doc/administration/operations/fast_ssh_key_lookup.md
```

This issue may occur if:

- You [use SELinux](../../../operations/fast_ssh_key_lookup.md#selinux-support-and-limitations).
- You don't use SELinux, and the `git` user cannot access the OpenSSH configuration file due to restricted file permissions.

In the latter case, the following output shows that only the `root` user can read this file:

```plaintext
sudo stat -c '%G:%U %A %a %n' /etc/ssh/sshd_config

root:root -rw------- 600 /etc/ssh/sshd_config
```

To allow the `git` user to read the OpenSSH configuration file, without changing the file owner or permissions, use `acl`:

```plaintext
sudo setfacl -m u:git:r /etc/ssh/sshd_config
```

#### Sync status Rake task

Current sync information can be found manually by running this Rake task on any
node running Rails (Puma, Sidekiq, or Geo Log Cursor) on the Geo **secondary** site.

GitLab does **not** verify objects that are stored in Object Storage. If you are using Object Storage, you will see all of the "verified" checks showing 0 successes. This is expected and not a cause for concern.

```shell
sudo gitlab-rake geo:status
```

The output includes:

- a count of "failed" items if any failures occurred
- the percentage of "succeeded" items, relative to the "total"

Example:

```plaintext
http://secondary.example.com/
-----------------------------------------------------
                        GitLab Version: 14.9.2-ee
                              Geo Role: Secondary
                         Health Status: Healthy
                  Project Repositories: succeeded 12345 / total 12345 (100%)
             Project Wiki Repositories: succeeded 6789 / total 6789 (100%)
                           Attachments: succeeded 4 / total 4 (100%)
                      CI job artifacts: succeeded 0 / total 0 (0%)
        Design management repositories: succeeded 1 / total 1 (100%)
                           LFS Objects: failed 1 / succeeded 2 / total 3 (67%)
                   Merge Request Diffs: succeeded 0 / total 0 (0%)
                         Package Files: failed 1 / succeeded 2 / total 3 (67%)
              Terraform State Versions: failed 1 / succeeded 2 / total 3 (67%)
                  Snippet Repositories: failed 1 / succeeded 2 / total 3 (67%)
               Group Wiki Repositories: succeeded 4 / total 4 (100%)
                    Pipeline Artifacts: failed 3 / succeeded 0 / total 3 (0%)
                     Pages Deployments: succeeded 0 / total 0 (0%)
                  Repositories Checked: failed 5 / succeeded 0 / total 5 (0%)
                Package Files Verified: succeeded 0 / total 10 (0%)
     Terraform State Versions Verified: succeeded 0 / total 10 (0%)
         Snippet Repositories Verified: succeeded 99 / total 100 (99%)
           Pipeline Artifacts Verified: succeeded 0 / total 10 (0%)
         Project Repositories Verified: succeeded 12345 / total 12345 (100%)
    Project Wiki Repositories Verified: succeeded 6789 / total 6789 (100%)
                         Sync Settings: Full
              Database replication lag: 0 seconds
       Last event ID seen from primary: 12345 (about 2 minutes ago)
               Last event ID processed: 12345 (about 2 minutes ago)
                Last status report was: 1 minute ago
```

Each item can have up to three statuses. For example, for `Project Repositories`, you see the following lines:

```plaintext
  Project Repositories: succeeded 12345 / total 12345 (100%)
  Project Repositories Verified: succeeded 12345 / total 12345 (100%)
  Repositories Checked: failed 5 / succeeded 0 / total 5 (0%)
```

The 3 status items are defined as follows:

- The `Project Repositories` output shows how many project repositories are synced from the primary to the secondary.
- The `Project Verified Repositories` output shows how many project repositories on this secondary have a matching repository checksum with the Primary.
- The `Repositories Checked` output shows how many project repositories have passed a local Git repository check (`git fsck`) on the secondary.

To find more details about failed items, check
[the `gitlab-rails/geo.log` file](../../../logs/log_parsing.md#find-most-common-geo-sync-errors)

If you notice replication or verification failures, you can try to [resolve them](replication.md#fixing-non-postgresql-replication-failures).

If there are Repository check failures, you can try to [resolve them](synchronization.md#find-repository-check-failures-in-a-geo-secondary-site).

##### Fixing errors found when running the Geo check Rake task

When running this Rake task, you may see error messages if the nodes are not properly configured:

```shell
sudo gitlab-rake gitlab:geo:check
```

- Rails did not provide a password when connecting to the database.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... Exception: fe_sendauth: no password supplied
  GitLab Geo is enabled ... Exception: fe_sendauth: no password supplied
  ...
  Checking Geo ... Finished
  ```

  Ensure you have the `gitlab_rails['db_password']` set to the plain-text
  password used when creating the hash for `postgresql['sql_user_password']`.

- Rails is unable to connect to the database.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1",  user "gitlab", database "gitlabhq_production", SSL on
  FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
  GitLab Geo is enabled ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL on
  FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
  ...
  Checking Geo ... Finished
  ```

  Ensure you have the IP address of the rails node included in `postgresql['md5_auth_cidr_addresses']`.
  Also, ensure you have included the subnet mask on the IP address: `postgresql['md5_auth_cidr_addresses'] = ['1.1.1.1/32']`.

- Rails has supplied the incorrect password.

  ```plaintext
  Checking Geo ...
  GitLab Geo is available ... Exception: FATAL:  password authentication failed for user "gitlab"
  FATAL:  password authentication failed for user "gitlab"
  GitLab Geo is enabled ... Exception: FATAL:  password authentication failed for user "gitlab"
  FATAL:  password authentication failed for user "gitlab"
  ...
  Checking Geo ... Finished
  ```

  Verify the correct password is set for `gitlab_rails['db_password']` that was
  used when creating the hash in  `postgresql['sql_user_password']` by running
  `gitlab-ctl pg-password-md5 gitlab` and entering the password.

- Check returns `not a secondary node`.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... yes
  GitLab Geo is enabled ... yes
  GitLab Geo tracking database is correctly configured ... not a secondary node
  Database replication enabled? ... not a secondary node
  ...
  Checking Geo ... Finished
  ```

  Ensure you have added the secondary site in the Admin Area under **Geo > Sites** on the web interface for the **primary** site.
  Also ensure you entered the `gitlab_rails['geo_node_name']`
  when adding the secondary site in the Admin Area of the **primary** site.

- Check returns `Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist`.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... no
    Try fixing it:
    Add a new license that includes the GitLab Geo feature
    For more information see:
    https://about.gitlab.com/features/gitlab-geo/
  GitLab Geo is enabled ... Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist
  LINE 8:                WHERE a.attrelid = '"geo_nodes"'::regclass
                                             ^
  :               SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                       pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
                       c.collname, col_description(a.attrelid, a.attnum) AS comment
                  FROM pg_attribute a
                  LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
                  LEFT JOIN pg_type t ON a.atttypid = t.oid
                  LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
                 WHERE a.attrelid = '"geo_nodes"'::regclass
                   AND a.attnum > 0 AND NOT a.attisdropped
                 ORDER BY a.attnum
  ...
  Checking Geo ... Finished
  ```

  When performing a PostgreSQL major version (9 > 10), update this is expected. Follow
  the [initiate-the-replication-process](../../setup/database.md#step-3-initiate-the-replication-process).

- Rails does not appear to have the configuration necessary to connect to the Geo tracking database.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... yes
  GitLab Geo is enabled ... yes
  GitLab Geo tracking database is correctly configured ... no
  Try fixing it:
  Rails does not appear to have the configuration necessary to connect to the Geo tracking database. If the tracking database is running on a node other than this one, then you may need to add configuration.
  ...
  Checking Geo ... Finished
  ```

  - If you are running the secondary site on a single node for all services, then follow [Geo database replication - Configure the secondary server](../../setup/database.md#step-2-configure-the-secondary-server).
  - If you are running the secondary site's tracking database on its own node, then follow [Geo for multiple servers - Configure the Geo tracking database on the Geo secondary site](../multiple_servers.md#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site)
  - If you are running the secondary site's tracking database in a Patroni cluster, then follow [Geo database replication - Configuring Patroni cluster for the tracking PostgreSQL database](../../setup/database.md#configuring-patroni-cluster-for-the-tracking-postgresql-database)
  - If you are running the secondary site's tracking database in an external database, then follow [Geo with external PostgreSQL instances](../../setup/external_database.md#configure-the-tracking-database)
  - If the Geo check task was run on a node which is not running a service which runs the GitLab Rails app (Puma, Sidekiq, or Geo Log Cursor), then this error can be ignored. The node does not need Rails to be configured.

##### Message: Machine clock is synchronized ... Exception

The Rake task attempts to verify that the server clock is synchronized with NTP. Synchronized clocks
are required for Geo to function correctly. As an example, for security, when the server time on the
primary site and secondary site differ by about a minute or more, requests between Geo sites
fail. If this check task fails to complete due to a reason other than mismatching times, it
does not necessarily mean that Geo will not work.

The Ruby gem which performs the check is hard coded with `pool.ntp.org` as its reference time source.

- Exception message `Machine clock is synchronized ... Exception: Timeout::Error`

  This issue occurs when your server cannot access the host `pool.ntp.org`.

- Exception message `Machine clock is synchronized ... Exception: No route to host - recvfrom(2)`

  This issue occurs when the hostname `pool.ntp.org` resolves to a server which does not provide a time service.

In this case, in GitLab 15.7 and later, [specify a custom NTP server using environment variables](#health-check-rake-task).

In GitLab 15.6 and earlier, use one of the following workarounds:

- Add entries in `/etc/hosts` for `pool.ntp.org` to direct the request to valid local time servers.
  This fixes the long timeout and the timeout error.
- Direct the check to any valid IP address. This resolves the timeout issue, but the check fails
  with the `No route to host` error, as noted above.

[Cloud native GitLab deployments](https://docs.gitlab.com/charts/advanced/geo/#set-the-geo-primary-site)
generate an error because containers in Kubernetes do not have access to the host clock:

```plaintext
Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
```

##### Message: `ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute INSERT in a read-only transaction`

When this error is encountered on a secondary site, it likely affects all usages of GitLab Rails such as `gitlab-rails` or `gitlab-rake` commands, as well the Puma, Sidekiq, and Geo Log Cursor services.

```plaintext
ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute INSERT in a read-only transaction
/opt/gitlab/embedded/service/gitlab-rails/app/models/application_record.rb:86:in `block in safe_find_or_create_by'
/opt/gitlab/embedded/service/gitlab-rails/app/models/concerns/cross_database_modification.rb:92:in `block in transaction'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/database.rb:332:in `block in transaction'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/database.rb:331:in `transaction'
/opt/gitlab/embedded/service/gitlab-rails/app/models/concerns/cross_database_modification.rb:83:in `transaction'
/opt/gitlab/embedded/service/gitlab-rails/app/models/application_record.rb:86:in `safe_find_or_create_by'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:21:in `by_name'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `block in populate!'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `map'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `populate!'
/opt/gitlab/embedded/service/gitlab-rails/config/initializers/fill_shards.rb:9:in `<top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb:7:in `<top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
```

The PostgreSQL read-replica database would be producing these errors:

```plaintext
2023-01-17_17:44:54.64268 ERROR:  cannot execute INSERT in a read-only transaction
2023-01-17_17:44:54.64271 STATEMENT:  /*application:web,db_config_name:main*/ INSERT INTO "shards" ("name") VALUES ('storage1') RETURNING "id"
```

This situation can occur during initial configuration when a secondary site is not yet aware that it is a secondary site.

To resolve the error, follow [Step 3. Add the secondary site](../configuration.md#step-3-add-the-secondary-site).

### Check if PostgreSQL replication is working

To check if PostgreSQL replication is working, check if:

- [Sites are pointing to the correct database node](#are-sites-pointing-to-the-correct-database-node).
- [Geo can detect the current site correctly](#can-geo-detect-the-current-site-correctly).

If you're still having problems, see the [advanced replication troubleshooting](replication.md).

#### Are sites pointing to the correct database node?

You should make sure your **primary** Geo [site](../../glossary.md) points to
the database node that has write permissions.

Any **secondary** sites should point only to read-only database nodes.

#### Can Geo detect the current site correctly?

Geo finds the current Puma or Sidekiq node's Geo [site](../../glossary.md) name in
`/etc/gitlab/gitlab.rb` with the following logic:

1. Get the "Geo node name" (there is
   [an issue to rename the settings to "Geo site name"](https://gitlab.com/gitlab-org/gitlab/-/issues/335944)):
   - Linux package: get the `gitlab_rails['geo_node_name']` setting.
   - GitLab Helm charts: get the `global.geo.nodeName` setting (see [Charts with GitLab Geo](https://docs.gitlab.com/charts/advanced/geo/index.html)).
1. If that is not defined, then get the `external_url` setting.

This name is used to look up the Geo site with the same **Name** in the **Geo Sites**
dashboard.

To check if the current machine has a site name that matches a site in the
database, run the check task:

```shell
sudo gitlab-rake gitlab:geo:check
```

It displays the current machine's site name and whether the matching database
record is a **primary** or **secondary** site.

```plaintext
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
```

```plaintext
This machine's Geo node name matches a database record ... no
  Try fixing it:
  You could add or update a Geo node database record, setting the name to "https://example.com/".
  Or you could set this machine's Geo node name to match the name of an existing database record: "London", "Shanghai"
  For more information see:
  doc/administration/geo/replication/troubleshooting/index.md#can-geo-detect-the-current-node-correctly
```

For more information about recommended site names in the description of the Name field, see
[Geo Admin Area Common Settings](../../../../administration/geo_sites.md#common-settings).

### Check OS locale data compatibility

If at all possible, all Geo nodes across all sites should be deployed with the same method and operating system, as defined in the [requirements for running Geo](../../index.md#requirements-for-running-geo).

If different operating systems or different operating system versions are deployed across Geo sites, you **must** perform a locale data compatibility check before setting up Geo. You must also check `glibc` when using a mixture of GitLab deployment methods. The locale might be different between a Linux package install, a GitLab Docker container, a Helm chart deployment, or external database services. See the [documentation on upgrading operating systems for PostgreSQL](../../../postgresql/upgrading_os.md), including how to check `glibc` version compatibility.

Geo uses PostgreSQL and Streaming Replication to replicate data across Geo sites. PostgreSQL uses locale data provided by the operating system's C library for sorting text. If the locale data in the C library is incompatible across Geo sites, it causes erroneous query results that lead to [incorrect behavior on secondary sites](https://gitlab.com/gitlab-org/gitlab/-/issues/360723).

For example, Ubuntu 18.04 (and earlier) and RHEL/CentOS 7 (and earlier) are incompatible with their later releases.
See the [PostgreSQL wiki for more details](https://wiki.postgresql.org/wiki/Locale_data_changes).

## Fixing common errors

This section documents common error messages reported in the Admin Area on the web interface, and how to fix them.

### Geo database configuration file is missing

GitLab cannot find or doesn't have permission to access the `database_geo.yml` configuration file.

In a Linux package installation, the file should be in `/var/opt/gitlab/gitlab-rails/etc`.
If it doesn't exist or inadvertent changes have been made to it, run `sudo gitlab-ctl reconfigure` to restore it to its correct state.

If this path is mounted on a remote volume, ensure your volume configuration
has the correct permissions.

### An existing tracking database cannot be reused

Geo cannot reuse an existing tracking database.

It is safest to use a fresh secondary, or reset the whole secondary by following
[Resetting Geo secondary site replication](replication.md#resetting-geo-secondary-site-replication).

It is risky to reuse a secondary site without resetting it because the secondary site may have missed some Geo events. For example, missed deletion events lead to the secondary site permanently having data that should be deleted. Similarly, losing an event which physically moves the location of data leads to data permanently orphaned in one location, and missing in the other location until it is re-verified. This is why GitLab switched to hashed storage, since it makes moving data unnecessary. There may be other unknown problems due to lost events.

If these kinds of risks do not apply, for example in a test environment, or if you know that the main Postgres database still contains all Geo events since the Geo site was added, then you can bypass this health check:

1. Get the last processed event time. In Rails console in the secondary site, run:

   ```ruby
   Geo::EventLogState.last.created_at.utc
   ```

1. Copy the output, for example `2024-02-21 23:50:50.676918 UTC`.
1. Update the created time of the secondary site to make it appear older. In Rails console in the primary site, run:

   ```ruby
   GeoNode.secondary_nodes.last.update_column(:created_at, DateTime.parse('2024-02-21 23:50:50.676918 UTC') - 1.second)
   ```

   This command assumes that the affected secondary site is the one that was created last.

1. Update the secondary site's status in **Admin > Geo > Sites**. In Rails console in the secondary site, run:

   ```ruby
   Geo::MetricsUpdateWorker.new.perform
   ```

1. The secondary site should appear healthy. If it does not, run `gitlab-rake gitlab:geo:check` on the secondary site, or try restarting Rails if you haven't done so since re-adding the secondary site.
1. To resync missing or out-of-date data, go to **Admin > Geo > Sites**.
1. Under the secondary site select **Replication Details**.
1. Select **Reverify all** for every data type.

### Geo site has a database that is writable which is an indication it is not configured for replication with the primary site

This error message refers to a problem with the database replica on a **secondary** site,
which Geo expects to have access to. It usually means, either:

- An unsupported replication method was used (for example, logical replication).
- The instructions to set up a [Geo database replication](../../setup/database.md) were not followed correctly.
- Your database connection details are incorrect, that is you have specified the wrong
  user in your `/etc/gitlab/gitlab.rb` file.

Geo **secondary** sites require two separate PostgreSQL instances:

- A read-only replica of the **primary** site.
- A regular, writable instance that holds replication metadata. That is, the Geo tracking database.

This error message indicates that the replica database in the **secondary** site is misconfigured and replication has stopped.

To restore the database and resume replication, you can do one of the following:

- [Reset the Geo secondary site replication](replication.md#resetting-geo-secondary-site-replication).
- [Set up a new Geo secondary using the Linux package](../../setup/index.md#using-linux-package-installations).

If you set up a new secondary from scratch, you must also [remove the old site from the Geo cluster](../remove_geo_site.md#removing-secondary-geo-sites).

### Geo site does not appear to be replicating the database from the primary site

The most common problems that prevent the database from replicating correctly are:

- **Secondary** sites cannot reach the **primary** site. Check credentials and
  [firewall rules](../../index.md#firewall-rules).
- SSL certificate problems. Make sure you copied `/etc/gitlab/gitlab-secrets.json` from the **primary** site.
- Database storage disk is full.
- Database replication slot is misconfigured.
- Database is not using a replication slot or another alternative and cannot catch-up because WAL files were purged.

Make sure you follow the [Geo database replication](../../setup/database.md) instructions for supported configuration.

### Geo database version (...) does not match latest migration (...)

If you are using the Linux package installation, something might have failed during upgrade. You can:

- Run `sudo gitlab-ctl reconfigure`.
- Manually trigger the database migration by running: `sudo gitlab-rake db:migrate:geo` as root on the **secondary** site.

### GitLab indicates that more than 100% of repositories were synced

This can be caused by orphaned records in the project registry. They are being cleaned
periodically using a registry worker, so give it some time to fix it itself.

### Secondary site shows "Unhealthy" in UI after changing the value of `external_url` for the primary site

If you have updated the value of `external_url` in `/etc/gitlab/gitlab.rb` for the primary site or changed the protocol from `http` to `https`, you may see that secondary sites are shown as `Unhealthy`. You may also find the following error in `geo.log`:

```plaintext
"class": "Geo::NodeStatusRequestService",
...
"message": "Failed to Net::HTTP::Post to primary url: http://primary-site.gitlab.tld/api/v4/geo/status",
  "error": "Failed to open TCP connection to <PRIMARY_IP_ADDRESS>:80 (Connection refused - connect(2) for \"<PRIMARY_ID_ADDRESS>\" port 80)"
```

In this case, make sure to update the changed URL on all your sites:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Geo > Sites**.
1. Change the URL and save the change.

### Message: `ERROR: canceling statement due to conflict with recovery` during backup

Running a backup on a Geo **secondary** [is not supported](https://gitlab.com/gitlab-org/gitlab/-/issues/211668).

When running a backup on a **secondary** you might encounter the following error message:

```plaintext
Dumping PostgreSQL database gitlabhq_production ...
pg_dump: error: Dumping the contents of table "notes" failed: PQgetResult() failed.
pg_dump: error: Error message from server: ERROR:  canceling statement due to conflict with recovery
DETAIL:  User query might have needed to see row versions that must be removed.
pg_dump: error: The command was: COPY public.notes (id, note, [...], last_edited_at) TO stdout;
```

To prevent a database backup being made automatically during GitLab upgrades on your Geo **secondaries**,
create the following empty file:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```
