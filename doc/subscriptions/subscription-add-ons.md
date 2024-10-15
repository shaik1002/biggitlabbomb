---
stage: Fulfillment
group: Subscription management
description: Seat assignment, GitLab Duo Pro add-on
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Subscription add-ons

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can purchase subscription add-ons to give users in your organization access to more GitLab features.
Subscription add-ons are purchased as additional seats in your subscription.
Access to features provided by subscription add-ons is managed through seat assignment. Subscription
add-ons can be assigned to billable users only.

## Purchase GitLab Duo Pro seats

You can purchase additional GitLab Duo Pro seats for your group namespace or self-managed instance. After you complete the purchase,
you must assign the seats to billable users so that they can use GitLab Duo Pro.

To purchase GitLab Duo Pro seats, you can use the Customers Portal, or you can contact the [GitLab Sales team](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/).

1. Sign in to the [GitLab Customers Portal](https://customers.gitlab.com/).
1. On the subscription card, select the vertical ellipsis (**{ellipsis_v}**).
1. Select **Buy GitLab Duo Pro**.
1. Enter the number of seats for GitLab Duo Pro.
1. Review the **Purchase summary** section.
1. From the **Payment method** dropdown list, select your payment method.
1. Select **Purchase seats**.

## Assign GitLab Duo Pro seats

Prerequisites:

- You must purchase the GitLab Duo Pro add-on.
- For self-managed and GitLab Dedicated, the GitLab Duo Pro add-on is available for GitLab 16.8 and later only.

After you purchase GitLab Duo Pro, you can assign seats to billable users to grant access to the add-on.

### For GitLab.com

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select the **GitLab Duo Pro** tab.
1. To the right of the user, turn on the toggle to assign GitLab Duo Pro.

To use Code Suggestions in any project or group, a user must be assigned a seat in at least one top-level group.

#### Enable automatic assignment of new users

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13637) in GitLab 17.0 [with a flag](../administration/feature_flags.md) named `auto_assign_gitlab_duo_pro_seats`.

You can enable automatic assignment of GitLab Duo Pro seats for new users. When this feature is enabled,
any member added to a top-level group, subgroup, or project is automatically allocated a GitLab Duo Pro
seat if one is available.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Locate **GitLab Duo Pro seats**.
1. Select the **Automatic assignment of GitLab Duo Pro seats** checkbox.

### For self-managed

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **GitLab Duo Pro**.
   - If the **GitLab Duo Pro** menu item is not available, synchronize your subscription
   after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
     synchronize subscription (**{retry}**).
1. To the right of the user, turn on the toggle to assign GitLab Duo Pro.

#### Configure network and proxy settings

For self-managed instances, to enable GitLab Duo features,
You must [enable network connectivity](../user/ai_features_enable.md#configure-gitlab-duo-on-a-self-managed-instance).

## Assign and remove GitLab Duo Pro seats in bulk

You can assign or remove seats in bulk for multiple users.

### For GitLab.com

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select the **GitLab Duo Pro** tab.
1. Select the users to assign or remove seats for:
   - To select multiple users, to the left of each user, select the checkbox.
   - To select all, select the checkbox at the top of the table.
1. Assign or remove seats:
   - To assign seats, select **Assign seat**, then **Assign seats** to confirm.
   - To remove users from seats, select **Remove seat**, then **Remove seats** to confirm.

### For self-managed

Administrators of self-managed instances can use a [Rake task](../raketasks/user_management.md#bulk-assign-users-to-gitlab-duo-pro) to assign or remove seats in bulk.

## Purchase additional GitLab Duo Pro seats

You can purchase additional GitLab Duo Pro seats for your group namespace or self-managed instance. After you complete the purchase, the seats are added to the total number of GitLab Duo Pro seats in your subscription.

Prerequisites:

- You must purchase the GitLab Duo Pro add-on.

### For GitLab.com

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select the **GitLab Duo Pro** tab.
1. Select **Add seats**.
1. In the Customers Portal, in the **Add additional seats** field, enter the number of seats. The amount
   cannot be higher than the number of seats in the subscription associated with your group namespace.
1. In the **Billing information** section, select the payment method from the dropdown list.
1. Select the **Privacy Policy** and **Terms of Service** checkbox.
1. Select **Purchase seats**.
1. Select the **GitLab SaaS** tab and refresh the page.

### For self-managed and GitLab Dedicated

Prerequisites:

- You must be an administrator.

1. Sign in to the [GitLab Customers Portal](https://customers.gitlab.com/).
1. On the **GitLab Duo Pro** section of your subscription card click **Add seats** button.
1. Enter the number of seats. The amount cannot be higher than the number of seats in the subscription.
1. Review the **Purchase summary** section.
1. From the **Payment method** dropdown list, select your payment method.
1. Select **Purchase seats**.

## Start GitLab Duo Pro trial

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

### On GitLab.com

Prerequisites:

- You must have an active paid Premium or Ultimate subscription.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Billing**.
1. Select **Start a free GitLab Duo Pro trial**.
1. Complete the fields.
1. Select **Continue**.
1. If prompted, select the group that the trial should be applied to.
1. Select **Activate my trial**.
1. [Assign seats](#assign-gitlab-duo-pro-seats) to the users who need access.

### On Self-managed and GitLab Dedicated

Prerequisites:

- You must have an active paid Premium or Ultimate subscription.
- You must have GitLab 16.8 or later and your instance must be able to [synchronize your subscription data](self_managed/index.md#subscription-data-synchronization) with GitLab.

1. Go to the [GitLab Duo Pro trial page](https://about.gitlab.com/solutions/gitlab-duo-pro/self-managed-and-gitlab-dedicated-trial/).
1. Complete the fields.

   - To find your subscription name:
     1. In the Customers Portal, on the **Subscriptions & purchases** page, find the subscription you want to apply the trial to.
     1. At the top of the page, the subscription name appears in a badge.

        ![Subscription name](img/subscription_name.png)
   - Ensure the email you submit for trial registration matches the email of the [subscription contact](customers_portal.md#change-your-subscription-contact).
1. Select **Submit**.

The trial automatically syncs to your instance within 24 hours. After the trial has synced, [assign seats](#assign-gitlab-duo-pro-seats) to users that you want to access GitLab Duo Pro.

## Automatic seat removal for seat overages

If your quantity of purchased GitLab Duo Pro seats is reduced, seat assignments are automatically removed to match the seat quantity available in the subscription.

For example:

- You have a 50 seat GitLab Duo Pro subscription with all seats assigned.
- You renew the subscription for 30 seats. The 20 users over subscription are automatically removed from GitLab Duo Pro seat assignment.
- If only 20 users were assigned a GitLab Duo Pro seat before renewal, then no removal of seats would occur.

Seats are selected for removal based on the following criteria, in this order:

1. Users who have not yet used Code Suggestions, ordered by most recently assigned.
1. Users who have used Code Suggestions, ordered by least recent usage of Code Suggestions.
