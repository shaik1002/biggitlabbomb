---
stage: AI-Powered
group: Custom Models
description: Get started with Self-Hosted AI Models.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Deploy a self-hosted large language model

DETAILS:
**Tier:** For a limited time, Ultimate. On October 17, 2024, Ultimate with [GitLab Duo Enterprise](https://about.gitlab.com/gitlab-duo/#pricing).
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

When you deploy a self-hosted model, you can:

- Manage the end-to-end transmission of requests to enterprise-hosted large
  language model (LLM) backends for GitLab Duo features.
- Keep all of these requests within that enterprise network, ensuring no calls
  to external architecture.
- Isolate the GitLab instance, AI Gateway, and self-hosted model within their own
  environment, ensuring complete privacy and high security for using AI features, with
  no reliance on public services.

When you use self-hosted models, you:

- Can choose any GitLab-approved LLM.
- Can keep all data and request/response logs in your own domain.
- Can select specific GitLab Duo features for your users.
- Do not have to rely on the GitLab shared AI Gateway.

You can connect supported models to LLM features. Model-specific prompts
and GitLab Duo feature support is provided by the GitLab Duo Self-Hosted Models
feature. For more information about this offering, see
[subscriptions](../../subscriptions/self_managed/index.md) and the
[Blueprint](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/custom_models/).

## Prerequisites

- You must be able to manage your own LLM infrastructure.
- You must have [GitLab Enterprise Edition](../../administration/license.md).

## Deploy a self-hosted model

To deploy a self-hosted large language model:

1. [Set up your self-hosted model infrastructure](../../administration/self_hosted_models/install_infrastructure.md) and connect it to your GitLab instance.
1. [Configure your GitLab instance to access self-hosted models](../../administration/self_hosted_models/configure_duo_features.md) using instance and group settings.

## Self-hosted models compared to the default GitLab AI vendor architecture

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    actor User
    participant GitLab
    participant AIGateway as AI Gateway
    participant SelfHostedModel as Self Hosted Model
    participant CloudConnector as Cloud Connector
    participant GitLabAIVendor as GitLab AI Vendor

    User ->> GitLab: Send request
    GitLab ->> GitLab: Check if self-hosted model is configured
    alt Self-hosted model configured
        GitLab ->> AIGateway: Create prompt and send request
        AIGateway ->> SelfHostedModel: Perform API request to AI model
        SelfHostedModel -->> AIGateway: Respond to the prompt
        AIGateway -->> GitLab: Forward AI response
    else
        GitLab ->> CloudConnector: Create prompt and send request
        CloudConnector ->> GitLabAIVendor: Perform API request to AI model
        GitLabAIVendor -->> CloudConnector: Respond to the prompt
        CloudConnector -->> GitLab: Forward AI response
    end
    GitLab -->> User: Forward AI response
```
