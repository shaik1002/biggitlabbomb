---
stage: SaaS Platforms
group: GitLab Dedicated
description: Available features and benefits.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Dedicated

GitLab Dedicated is a fully isolated, single-tenant SaaS solution that is:

- Hosted and managed by GitLab, Inc.
- Deployed on AWS in a cloud [region](data_residency_and_high_availability.md#available-aws-regions) of your choice.

GitLab Dedicated removes the overhead of platform management to increase your operational efficiency, reduce risk, and enhance the speed and agility of your organization. Each GitLab Dedicated instance is highly available with disaster recovery and deployed into the cloud region of your choice. GitLab teams fully manage the maintenance and operations of each isolated instance, so customers can access our latest product improvements while meeting the most complex compliance standards.

It's the offering of choice for enterprises and organizations in highly regulated industries that have complex regulatory, compliance, and data residency requirements.

## Available features

### Advanced search

GitLab Dedicated uses the [advanced search functionality](../../integration/advanced_search/elasticsearch.md).

### Security

#### Authentication and authorization

GitLab Dedicated supports instance-level [SAML OmniAuth](../../integration/saml.md) functionality using a single SAML provider. Your GitLab Dedicated instance acts as the service provider, and you must provide the necessary [configuration](../../integration/saml.md#configure-saml-support-in-gitlab) in order for GitLab to communicate with your IdP. For more information, see how to [configure SAML](../../administration/dedicated/configure_instance.md#saml) for your instance.

- SAML [request signing](../../integration/saml.md#sign-saml-authentication-requests-optional), [group sync](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync), and [SAML groups](../../integration/saml.md#configure-users-based-on-saml-group-membership) are supported.

#### Secure networking

GitLab Dedicated offers public connectivity by default with support for IP allowlists. You can [optionally specify a list of IP addresses](../../administration/dedicated/configure_instance.md#ip-allowlist) that can access your GitLab Dedicated instance. Subsequently, when an IP not on the allowlist tries to access your instance the connection is refused.

Private connectivity using [AWS PrivateLink](https://aws.amazon.com/privatelink/) is also offered as an option. Both [inbound](../../administration/dedicated/configure_instance.md#inbound-private-link) and [outbound](../../administration/dedicated/configure_instance.md#outbound-private-link) PrivateLinks are supported. When connecting to internal resources over an outbound PrivateLink with non public certificates, you can specify a list of certificates that are trusted by GitLab. These certificates can be provided when [updating your instance configuration](../../administration/dedicated/configure_instance.md#custom-certificates).

#### Encryption

Data is encrypted at rest and in transit using the latest encryption standards.

#### Bring your own key encryption

During onboarding, you can specify an AWS KMS encryption key stored in your own AWS account that GitLab uses to encrypt the data for your Dedicated instance. This gives you full control over the data you store in GitLab.

#### SMTP

Email sent from GitLab Dedicated uses [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/). The connection to Amazon SES is encrypted.

If you would rather send application email using an SMTP server instead of Amazon SES, you can [configure your own email service](../../administration/dedicated/configure_instance.md#smtp-email-service).

### Compliance and certifications

GitLab Dedicated is trusted by highly regulated customers in part due to our ability to transparently demonstrate compliance with various regulations, certifications, and compliance frameworks.

You can view compliance and certification details, and download compliance artifacts from the [GitLab Dedicated Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated).

#### Access controls

GitLab Dedicated adheres to the
[principle of least privilege](https://handbook.gitlab.com/handbook/security/access-management-policy/#principle-of-least-privilege)
to control access to customer tenant environments. Tenant AWS accounts live under
a top-level GitLab Dedicated AWS parent organization. Access to the AWS Organization
is restricted to select GitLab team members. All user accounts within the AWS Organization
follow the overall [GitLab Access Management Policy](https://handbook.gitlab.com/handbook/security/access-management-policy/).
Direct access to customer tenant environments is restricted to a single Hub account.
The GitLab Dedicated Control Plane uses the Hub account to perform automated actions
over tenant accounts when managing environments. Similarly, GitLab Dedicated engineers
do not have direct access to customer tenant environments.
In [break glass](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/blob/main/engineering/breaking_glass.md)
situations, where access to resources in the tenant environment is required to
address a high-severity issue, GitLab engineers must go through the Hub account
to manage those resources. This is done via an approval process, and after permission
is granted, the engineer will assume an IAM role on a temporary basis to access
tenant resources through the Hub account. All actions within the hub account and
tenant account are logged to CloudTrail.

Inside tenant accounts, GitLab leverages Intrusion Detection and Malware Scanning capabilities from AWS GuardDuty. Infrastructure logs are monitored by the GitLab Security Incident Response Team to detect anomalous events.

#### Audit and observability

GitLab Dedicated provides access to [audit and system logs](../../administration/dedicated/configure_instance.md#access-to-application-logs) generated by the application.

### Bring your own domain

You can use your own hostname to access your GitLab Dedicated instance. Instead of `tenant_name.gitlab-dedicated.com`, you can use a hostname for a domain that you own, like `gitlab.my-company.com`. Optionally, you can also provide a custom hostname for the bundled container registry and KAS services for your GitLab Dedicated instance. For example, `gitlab-registry.my-company.com` and `gitlab-kas.my-company.com`.

Add a custom hostname to:

- Increase control over branding
- Avoid having to migrate away from an existing domain already configured for a self-managed instance

When you add a custom hostname:

- The hostname is included in the external URL used to access your instance.
- Any connections to your instance using the previous domain names are no longer available.

To add a custom hostname after your instance is created, submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

NOTE:
Custom hostnames for GitLab Pages are not supported. If you use GitLab Pages, the URL to access the Pages site for your GitLab Dedicated instance would be `tenant_name.gitlab-dedicated.site`.

### Application

GitLab Dedicated comes with the self-managed [Ultimate feature set](https://about.gitlab.com/pricing/feature-comparison/) with the exception of the [unsupported features](#features-that-are-not-available) listed below.

#### GitLab Pages

You can use [GitLab Pages](../../user/project/pages/index.md) on GitLab Dedicated to host your static website. The domain name is `tenant_name.gitlab-dedicated.site`, where `tenant_name` is the same as your instance URL.

NOTE:
Custom domains for GitLab Pages are not supported. For example, if you added a custom domain named `gitlab.my-company.com`, the URL to access the Pages site for your GitLab Dedicated instance would still be `tenant_name.gitlab-dedicated.site`.

You can control access to your Pages website with:

- [GitLab Pages access control](../../user/project/pages/pages_access_control.md).
- [IP allowlists](../../administration/dedicated/configure_instance.md#ip-allowlist). Any existing IP allowlists for your GitLab Dedicated instances are applied.

GitLab Pages for Dedicated:

- Is enabled by default.
- Only works in the primary site if [Geo](../../administration/geo/index.md) is enabled.
- Is not included as part of instance migrations to GitLab Dedicated.

The following GitLab Pages features are not available for GitLab Dedicated:

- Custom domains
- PrivateLink access
- Namespaces in URL path
- Let's Encrypt integration
- Reduced authentication scope
- Running Pages behind a proxy

#### Hosted runners

[Hosted runners for GitLab Dedicated](../../administration/dedicated/hosted_runners.md) allow you to scale CI/CD workloads with no maintenance overhead.

#### Self-managed runners

As an alternative to using hosted runners, you can use your own runners for your GitLab Dedicated instance.

To use self-managed runners, install [GitLab Runner](https://docs.gitlab.com/runner/install/) on infrastructure that you own or manage.

#### OpenID Connect

You can use [GitLab as an OpenID Connect identity provider](../../integration/openid_connect_provider.md). If you use an IP allowlist to restrict access to your instance, you can [enable OpenID Connect requests](../../administration/dedicated/configure_instance.md#enable-openid-connect-for-your-ip-allowlist) while maintaining your IP restrictions.

#### Migration

To help you migrate your data to GitLab Dedicated, choose from the following options:

1. When migrating from another GitLab instance, you can import groups and projects by either:
   - Using [direct transfer](../../user/group/import/index.md).
   - Using the [direct transfer](../../api/bulk_imports.md) API.
1. When migrating from third-party services, you can use [the GitLab importers](../../user/project/import/index.md#supported-import-sources).
1. You can also engage [Professional Services](../../user/project/import/index.md#migrate-by-engaging-professional-services).

### Pre-production environments

GitLab Dedicated supports pre-production environments that match the configuration of production environments. You can use pre-production environments to:

- Test new features before implementing them in production.
- Test configuration changes before applying them in production.

Pre-production environments must be purchased as an add-on to your GitLab Dedicated subscription, with no additional licenses required.

The following capabilities are available:

- Flexible sizing: Match the size of your production environment or use a smaller reference architecture.
- Version consistency: Runs the same GitLab version as your production environment.

Limitations:

- Single-region deployment only.
- No SLA commitment.
- Cannot run newer versions than production.

## Features that are not available

### GitLab application features

The following GitLab application features are not available:

- LDAP, smart card, or Kerberos authentication
- Multiple login providers
- FortiAuthenticator, or FortiToken 2FA
- Reply-by email
- Service Desk
- Some GitLab Duo AI capabilities
  - View the [list of AI features to see which ones are supported](../../user/ai_features.md).
  - Refer to our [direction page](https://about.gitlab.com/direction/saas-platforms/dedicated/#supporting-ai-features-on-gitlab-dedicated) for more information.
- Features other than [available features](#available-features) that must be configured outside of the GitLab user interface
- Any functionality or feature behind a Feature Flag that is toggled `off` by default.

The following features will not be supported:

- Mattermost
- [Server-side Git hooks](../../administration/server_hooks.md).
  GitLab Dedicated is a SaaS service, and access to the underlying infrastructure is only available to GitLab Inc. team members. Due to the nature of server side configuration, there is a possible security concern of running arbitrary code on Dedicated services, as well as the possible impact that can have on the service SLA. Use the alternative [push rules](../../user/project/repository/push_rules.md) or [webhooks](../../user/project/integrations/webhooks.md) instead.
- Interacting with GitLab [Feature Flags](../../administration/feature_flags.md). [Feature flags support the development and rollout of new or experimental features](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags) on GitLab.com. Features behind feature flags are not considered ready for production use, are experimental and therefore unsafe for GitLab Dedicated. Stability and SLAs may be affected by changing default settings.

### GitLab Dedicated service features

The following operational features are not available:

- Multiple Geo secondaries (Geo replicas) beyond the secondary site included by default
- [Geo proxying](../../administration/geo/secondary_proxy/index.md) and using a unified URL
- Self-serve purchasing and configuration
- Multiple login providers
- Support for deploying to non-AWS cloud providers, such as GCP or Azure
- Observability Dashboard using Switchboard

## Planned features

For more information about the planned improvements to GitLab Dedicated,
see the [category direction page](https://about.gitlab.com/direction/saas-platforms/dedicated/).

## Interested in GitLab Dedicated?

Learn more about GitLab Dedicated and [talk to an expert](https://about.gitlab.com/dedicated/).
