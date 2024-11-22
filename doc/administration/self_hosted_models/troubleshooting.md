---
stage: AI-Powered
group: Custom Models
description: Troubleshooting tips for deploying self-hosted models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting GitLab Duo Self-Hosted Models

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

If the response is not `200`, this means that AI Gateway is not installed correctly. To resolve, follow the [documentation on how to install AI Gateway](install_infrastructure.md).

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
