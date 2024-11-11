---
stage: AI-Powered
group: Custom Models
description: Troubleshooting tips for deploying self-hosted models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting GitLab Duo Self-Hosted Models

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

When working with GitLab Duo Self-Hosted Models, you might encounter issues.

Before you begin troubleshooting, you should:

- Be able to access open the [`gitlab-rails` console](../../administration/operations/rails_console.md).
- Open a shell in the AI Gateway Docker image.
- Know the endpoint where your:
  - AI Gateway is hosted.
  - Model is hosted.
- Enable the feature flag `expanded_ai_logging` on the `gitlab-rails` console:

  ```ruby
  Feature.enable(:expanded_ai_logging)
  ```

  Now, requests and responses from GitLab to the AI Gateway are logged to [`llm.log`](../logs/index.md#llmlog)

## Use debugging scripts

We provide two debugging scripts to help administrators verify their self-hosted
model configuration.

1. Debug the GitLab to AI Gateway connection. From your GitLab instance, run the
   [Rake task](../../raketasks/index.md):

   ```shell
   gitlab-rake gitlab:duo:verify_self_hosted_setup
   ```

1. Debug the AI Gateway setup. For your AI Gateway container, run:

   ```shell
   docker exec -it <ai-gateway-container> sh
   poetry run python scripts/troubleshoot_selfhosted_installation.py --model-name "codegemma_7b" --model-endpoint
   "http://localhost:4000"
   ```

Verify the output of the commands, and fix accordingly.

If both commands are successful, but GitLab Duo Code Suggestions is still not working,
raise an issue on the issue tracker.

## Check if GitLab can make a request to the model

From the GitLab Rails console, verify that GitLab can make a request to the model
by running:

```ruby
model_name = "<your_model_name>"
model_endpoint = "<your_model_endpoint>"
model_api_key = "<your_model_api_key>"
body = {:prompt_components=>[{:type=>"prompt", :metadata=>{:source=>"GitLab EE", :version=>"17.3.0"}, :payload=>{:content=>[{:role=>:user, :content=>"Hello"}], :provider=>:litellm, :model=>model_name, :model_endpoint=>model_endpoint, :model_api_key=>model_api_key}}]}
ai_gateway_url = Gitlab::AiGateway.url # Verify that it's not nil
client = Gitlab::Llm::AiGateway::Client.new(User.find_by_id(1), service_name: :self_hosted_models)
client.complete(url: "#{ai_gateway_url}/v1/chat/agent", body: body)
```

This should return a response from the model in the format:

```ruby
{"response"=> "<Model response>",
 "metadata"=>
  {"provider"=>"litellm",
   "model"=>"<>",
   "timestamp"=>1723448920}}
```

If that is not the case, this might means one of the following:

- The user might not have access to Code Suggestions. To resolve,
  [check if a user can request Code Suggestions](#check-if-a-user-can-request-code-suggestions).
- The GitLab environment variables are not configured correctly. To resolve, [check that the GitLab environmental variables are set up correctly](#check-that-gitlab-environmental-variables-are-set-up-correctly).
- The GitLab instance is not configured to use self-hosted models. To resolve, [check if the GitLab instance is configured to use self-hosted models](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models).
- The AI Gateway is not reachable. To resolve, [check if GitLab can make an HTTP request to the AI Gateway](#check-if-gitlab-can-make-an-http-request-to-ai-gateway).
- When the LLM server is installed on the same instance as the AI Gateway container, local requests may not work. To resolve, [allow local requests from the Docker container](#llm-server-is-not-available-inside-ai-gateway-container).

## Check if a user can request Code Suggestions

In the GitLab Rails console, check if a user can request Code Suggestions by running:

```ruby
User.find_by_id("<user_id>").can?(:access_code_suggestions)
```

If this returns `false`, it means some configuration is missing, and the user
cannot access Code Suggestions.

This missing configuration might be because of either of the following:

- The license is not valid. To resolve, [check or update your license](../license_file.md#see-current-license-information).
- GitLab Duo was not configured to use a self-hosted model. To resolve, [check if the GitLab instance is configured to use self-hosted models](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models).

## Check if GitLab instance is configured to use self-hosted-models

To check if GitLab Duo was configured correctly:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **AI-powered features**.
1. Under **Features**, check that **Code Suggestions** and **Code generation** are set to **Self-hosted model**.

## Check that GitLab environmental variables are set up correctly

To check if the GitLab environmental variables are set up correctly, run the
following on the GitLab Rails console:

```ruby
ENV["AI_GATEWAY_URL"] == "<your-ai-gateway-endpoint>"
```

If the environmental variables are not set up correctly, set them by following the
[Linux package custom environment variables setting documentation](https://docs.gitlab.com/omnibus/settings/environment-variables.html).

## Check if GitLab can make an HTTP request to AI Gateway

In the GitLab Rails console, verify that GitLab can make an HTTP request to AI
Gateway by running:

```ruby
HTTParty.get('<your-aigateway-endpoint>/monitoring/healthz', headers: { 'accept' => 'application/json' }).code
```

If the response is not `200`, this means either of the following:

- The network is not properly configured to allow GitLab to reach the AI Gateway container. Contact your network administrator to verify the setup.
- AI Gateway is not able to process requests. To resolve this issue, [check if the AI Gateway can make a request to the model](#check-if-ai-gateway-can-make-a-request-to-the-model).

## Check if AI Gateway can make a request to the model

From the AI Gateway container, make an HTTP request to the AI Gateway API for a
Code Suggestion. Replace:

- `<your_model_name>` with the name of the model you are using. For example `mistral` or `codegemma`.
- `<your_model_endpoint>` with the endpoint where the model is hosted.

```shell
docker exec -it <ai-gateway-container> sh
curl --request POST "http://localhost:5052/v1/chat/agent" \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --data '{ "prompt_components": [ { "type": "string", "metadata": { "source": "string", "version": "string" }, "payload": { "content": "Hello", "provider": "litellm", "model": "<your_model_name>", "model_endpoint": "<your_model_endpoint>" } } ], "stream": false }'
```

If the request fails, the:

- AI Gateway might not be configured properly to use self-hosted models. To resolve this,
  [check that the AI Gateway environmental variables are set up correctly](#check-that-ai-gateway-environmental-variables-are-set-up-correctly).
- AI Gateway might not be able to access the model. To resolve,
  [check if the model is reachable from the AI Gateway](#check-if-the-model-is-reachable-from-ai-gateway).
- Model name or endpoint might be incorrect. Check the values, and correct them
  if necessary.

## Check if AI Gateway can process requests

```shell
docker exec -it <ai-gateway-container> sh
curl '<your-aigateway-endpoint>/monitoring/healthz'
```

If the response is not `200`, this means that AI Gateway is not installed correctly. To resolve, follow the [documentation on how to install AI Gateway](../../install/install_ai_gateway.md).

## Check that AI Gateway environmental variables are set up correctly

To check that the AI Gateway environmental variables are set up correctly, run the
following in a console on the AI Gateway container:

```shell
docker exec -it <ai-gateway-container> sh
echo $AIGW_AUTH__BYPASS_EXTERNAL # must be true
echo $AIGW_CUSTOM_MODELS__ENABLED # must be true
```

If the environmental variables are not set up correctly, set them by
[creating a container](../../install/install_ai_gateway.md#find-the-ai-gateway-release).

## Check if the model is reachable from AI Gateway

Create a shell on the AI Gateway container and make a curl request to the model.
If you find that the AI Gateway cannot make that request, this might be caused by the:

1. Model server not functioning correctly.
1. Network settings around the container not being properly configured to allow
   requests to where the model is hosted.

To resolve this, contact your network administrator.

## The image's platform does not match the host

When [finding the AI Gateway release](../../install/install_ai_gateway.md#find-the-ai-gateway-release),
you might get an error that states `The requested image’s platform (linux/amd64) does not match the detected host`.

To work around this error, add `--platform linux/amd64` to the `docker run` command:

```shell
docker run --platform linux/amd64 -e AIGW_GITLAB_URL=<your-gitlab-endpoint> <image>
```

## LLM server is not available inside AI Gateway container

If the LLM server is installed on the same instance as the AI Gateway container, it may not be accessible through the local host.

To resolve this:

1. Include `--network host` in the `docker run` command to enable local requests from the AI Gateway container.
1. Use the `-e AIGW_FASTAPI__METRICS_PORT=8083` flag to address the port conflicts.

```shell
docker run --network host -e AIGW_GITLAB_URL=<your-gitlab-endpoint> -e AIGW_FASTAPI__METRICS_PORT=8083 <image>
```

## vLLM 404 Error

If you encounter a **404 error** while using vLLM, follow these steps to resolve the issue:

1. Create a chat template file named `chat_template.jinja` with the following content:

   ```jinja
   {%- for message in messages %}
     {%- if message["role"] == "user" %}
       {{- "[INST] " + message["content"] + "[/INST]" }}
     {%- elif message["role"] == "assistant" %}
       {{- message["content"] }}
     {%- elif message["role"] == "system" %}
       {{- bos_token }}{{- message["content"] }}
     {%- endif %}
   {%- endfor %}
   ```

1. When running the vLLM command, ensure you specify the `--served-model-name`. For example:

   ```shell
   vllm serve "mistralai/Mistral-7B-Instruct-v0.3" --port <port> --max-model-len 17776 --served-model-name mistral --chat-template chat_template.jinja
   ```

1. Check the vLLM server URL in the GitLab UI to make sure that URL includes the `/v1` suffix. The correct format is:

   ```shell
   http(s)://<your-host>:<your-port>/v1
   ```

## Code Suggestions access error

If you are experiencing issues accessing Code Suggestions after setup, try the following steps:

1. In the Rails console, check and verify the license parameters:

   ```shell
   sudo gitlab-rails console
   user = User.find(id) # Replace id with the user provisioned with GitLab Duo Enterprise seat
   Ability.allowed?(user, :access_code_suggestions) # Must return true
   ```

1. Check if the necessary features are enabled and available:

   ```shell
   Feature.enabled?(:self_hosted_models_beta_ended) # Should be false
   ::Ai::FeatureSetting.code_suggestions_self_hosted? # Should be true
   ```

1. If any feature is enabled and does not need to be, disable it:

   ```ruby
   Feature.disable(:self_hosted_models_beta_ended)
   ```

## Verify GitLab setup

To verify your GitLab self-managed setup, run the following command:

```shell
gitlab-rake gitlab:duo:verify_self_hosted_setup
```

## No logs generated in AI Gateway server

If no logs are generated in the **AI Gateway server**, follow these steps to troubleshoot:

1. Ensure the `expanded_ai_logging` feature flag is enabled:

   ```ruby
   Feature.enable(:expanded_ai_logging)
   ```

1. Run the following commands to view the GitLab Rails logs for any errors:

   ```shell
   sudo gitlab-ctl tail
   sudo gitlab-ctl tail sidekiq
   ```

1. Look for keywords like "Error" or "Exception" in the logs to identify any underlying issues.

## SSL certificate errors and key de-serialization issues in AI Gateway Container

When attempting to initiate a Duo Chat inside the AI Gateway container, SSL certificate errors and key deserialization issues may occur.

The system might encounter issues loading the PEM file, resulting in errors like:

```plaintext
JWKError: Could not deserialize key data. The data may be in an incorrect format, the provided password may be incorrect, or it may be encrypted with an unsupported algorithm.
```

To resolve the SSL certificate error:

- Set the appropriate certificate bundle path in the Docker container using the following environment variables:
  - `SSL_CERT_FILE=/path/to/ca-bundle.pem`
  - `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`
