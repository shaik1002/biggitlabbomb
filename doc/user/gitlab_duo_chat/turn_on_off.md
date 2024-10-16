---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Control GitLab Duo Chat availability

GitLab Duo Chat can be turned on and off, and availability changed.

## For GitLab.com

For a limited time, GitLab Duo Chat is automatically available for all GitLab.com users
who are members of at least one group with a Premium or Ultimate subscription.

## For self-managed

To enable GitLab Duo Chat on a self-managed instance,
you must have the following prerequisites.

Prerequisites:

- You must have GitLab version 16.8 or later. You should use the latest GitLab version to benefit from the latest improvements to GitLab Duo Chat. The generally available version of GitLab Duo Chat in GitLab 16.11 has significant improvements in the quality of the answers.
- You must have a Premium or Ultimate subscription that is [synchronized with GitLab](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/). To make sure GitLab Duo Chat works immediately, administrators can
  [manually synchronize your subscription](#manually-synchronize-your-subscription).
- You must have [enabled network connectivity](../gitlab_duo/turn_on_off.md#configure-gitlab-duo-on-a-self-managed-instance).
- All of the users in your instance must have the latest version of their IDE extension.

Then, depending on the version of GitLab you have, you can enable GitLab Duo Chat.

### In GitLab 16.11 and later

In GitLab 16.11 and later, GitLab Duo Chat is generally available
and automatically enabled for all users who have a subscription to the Premium or Ultimate tier.

You do not need to do anything to enable GitLab Duo Chat if you have GitLab 16.11 or later.

### In earlier GitLab versions

In GitLab 16.8, 16.9, and 16.10, GitLab Duo Chat is available in beta. To enable GitLab Duo Chat for your self-managed GitLab instance, an administrator must enable experiment and beta features:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **AI-powered features** and select **Enable Experiment and Beta AI-powered features**.
1. Select **Save changes**.
1. To make sure GitLab Duo Chat works immediately, you must
   [manually synchronize your subscription](#manually-synchronize-your-subscription).

NOTE:
Usage of GitLab Duo Chat beta is governed by the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using GitLab Duo Chat](../gitlab_duo/data_usage.md).

### Manually synchronize your subscription

You can [manually synchronize your subscription](../../subscriptions/self_managed/index.md#manually-synchronize-your-subscription-details) if either:

- You have just purchased a subscription for the Premium or Ultimate tier, or have recently assigned seats for Duo Pro, and you have upgraded to GitLab 16.8.
- You already have a subscription for the Premium or Ultimate tier, or you have recently assigned seats for Duo Pro, and you have upgraded to GitLab 16.8.

Without the manual synchronization, it might take up to 24 hours to activate GitLab Duo Chat on your instance.

## For GitLab Dedicated

In GitLab 16.11 and later, on GitLab Dedicated, GitLab Duo Chat is generally available and
automatically enabled for those with GitLab Duo Pro or Enterprise.

In GitLab 16.8, 16.9, and 16.10, on GitLab Dedicated, GitLab Duo Chat is available in beta.

## Disable GitLab Duo Chat

To limit the data that Duo Chat has access to, follow the instructions for
[disabling GitLab Duo features](../../user/gitlab_duo/turn_on_off.md#turn-off-gitlab-duo-features).

## Disable Chat in VS Code

To disable GitLab Duo Chat in VS Code:

1. Go to **Settings > Extensions > GitLab Workflow (GitLab VS Code Extension)**.
1. Clear the **Enable GitLab Duo Chat assistant** checkbox.
