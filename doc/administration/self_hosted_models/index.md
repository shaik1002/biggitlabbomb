---
stage: AI-Powered
group: Custom Models
description: Get started with self-hosted AI models.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Self-Hosted Models

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

To maintain full control over your data privacy, security, and the deployment of large language models (LLMs) in your own infrastructure, use GitLab Duo Self-Hosted Models.

By deploying self-hosted models, you can manage the entire lifecycle of requests made to LLM backends for GitLab Duo features, ensuring that all requests stay within your enterprise network and avoiding external dependencies.

## Why use self-hosted models

With self-hosted models, you can:

- Choose any GitLab-approved LLM.
- Retain full control over data by keeping all request/response logs within your domain, ensuring complete privacy and security with no external API calls.
- Isolate the GitLab instance, AI Gateway, and models within your own environment.
- Select specific GitLab Duo features tailored to your users.
- Eliminate reliance on the shared GitLab AI Gateway.

This setup ensures enterprise-level privacy and flexibility, allowing seamless integration of your LLMs with GitLab Duo features.

### Prerequisites

Before setting up a self-hosted model infrastructure, you must have:

- A [supported model](supported_models_and_hardware_requirements.md) (either cloud-based or on-premises).
- A [supported serving platform](supported_llm_serving_platforms.md) (either cloud-based or on-premises).
- A locally hosted or GitLab.com AI Gateway.
- GitLab Ultimate + [Duo Enterprise license](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?toggle=gitlab-duo-pro).

## Choose a configuration type

There are two configuration options for self-managed customers:

- [**GitLab.com AI Gateway**](configuration_types.md#gitlabcom-ai-gateway):
  Use the GitLab-hosted AI Gateway with external
  LLM providers (for example, Google Vertex or Anthropic).
- [**Self-hosted AI Gateway**](configuration_types.md#self-hosted-ai-gateway):
  Deploy your own AI Gateway and LLMs within
  your infrastructure, without relying on external public services.

Before setting up a self-hosted model infrastructure, you must decide which
configuration type to implement.

## Set up a self-hosted infrastructure

To set up a fully isolated self-hosted model infrastructure:

1. **Install a Large Language Model (LLM) Serving Infrastructure**

   - We support various platforms for serving and hosting your LLMs, such as vLLM, AWS Bedrock, and Azure OpenAI. To help you choose the most suitable option for effectively deploying your models, see the [supported LLM platforms documentation](supported_llm_serving_platforms.md) for more information on each platform's features.

   - We provide a comprehensive matrix of supported models along with their specific features and hardware requirements. To help select models that best align with your infrastructure needs for optimal performance, see the [supported models and hardware requirements documentation](supported_models_and_hardware_requirements.md).

1. **Install the GitLab AI Gateway**
   [Install the AI Gateway](../../install/install_ai_gateway.md) to efficiently configure your AI infrastructure.

1. **Configure GitLab Duo features**
   See the [Configure GitLab Duo features documentation](configure_duo_features.md) for instructions on how to customize your environment to effectively meet your operational needs.

1. **Enable logging**
   You can find configuration details for enabling logging within your environment. For help in using logs to track and manage your system's performance effectively, see the [logging documentation](logging.md).

## Related topics

- [Import custom models into Amazon Bedrock](https://www.youtube.com/watch?v=CA2AXfWWdpA)
- [Troubleshooting](troubleshooting.md)
