---
stage: AI-Powered
group: Custom Models
description: Configure your GitLab instance to use self-hosted models.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure GitLab to access self-hosted models

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

To configure your GitLab instance to access the available self-hosted models in your infrastructure:

1. Use a [locally hosted or GitLab.com AI gateway](index.md#choose-a-configuration-type).
1. Configure your GitLab instance.
1. Configure the self-hosted model.
1. Configure the GitLab Duo features to use your self-hosted model.

## Configure your GitLab instance

Prerequisites:

- [Upgrade to the latest version of GitLab](../../update/index.md).

To configure your GitLab instance to access the AI gateway:

1. Where your GitLab instance is installed, update the `/etc/gitlab/gitlab.rb` file:

   ```shell
   sudo vim /etc/gitlab/gitlab.rb
   ```

1. Add and save the following environment variables:

   ```ruby
   gitlab_rails['env'] = {
   'GITLAB_LICENSE_MODE' => 'production',
   'CUSTOMER_PORTAL_URL' => 'https://customers.gitlab.com',
   'AI_GATEWAY_URL' => '<path_to_your_ai_gateway>:<port>'
   }
   ```

1. Run reconfigure:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure the self-hosted model

Prerequisites:

- You must be an administrator.

To configure a self-hosted model:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Self-hosted models**.
   - If the **Self-hosted models** menu item is not available, synchronize your
     subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
        synchronize subscription (**{retry}**).
1. Select **Add self-hosted model**.
1. Complete the fields:
   - **Deployment name**: Enter a name to uniquely identify the model deployment, for example, `Mixtral-8x7B-it-v0.1 on GCP`.
   - **Model family**: Select the model family the deployment belongs to. Only GitLab-approved models
     are in this list.
   - **Endpoint**: Enter the URL where the model is hosted.
     - For models hosted through vLLM, it is essential to suffix the URL with `/v1`.
   - **API key**: Optional. Add an API key if you need one to access the model.
   - **Model identifier (optional)**: Optional. The model identifier is based on your deployment method:

     | Deployment method | Format | Example |
     |-------------|---------|---------|
     | vLLM | `custom_openai/<name of the model served through vLLM>` | `custom_openai/Mixtral-8x7B-Instruct-v0.1` |
     | Bedrock | `bedrock/<model ID of the model>` | `bedrock/mistral.mixtral-8x7b-instruct-v0:1` |
     | Azure | `azure/<model ID of the model>` | `azure/gpt-35-turbo` |
     | Others | The field is optional |  |

1. Select **Create self-hosted model**.

## Configure GitLab Duo features to use self-hosted models

Prerequisites:

- You must be an administrator.

### View configured features

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Self-hosted models**.
   - If the **Self-hosted models** menu item is not available, synchronize your
     subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
        synchronize subscription (**{retry}**).
1. Select the **AI-powered features** tab.

### Configure the feature to use a self-hosted model

Configure the GitLab Duo feature to send queries to the configured self-hosted model:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Self-hosted models**.
1. Select the **AI-powered features** tab.
1. For the feature you want to configure, from the dropdown list, choose the self-hosted model you want to use. For example, `Mistral`.
