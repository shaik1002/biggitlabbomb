---
stage: AI-powered
group: Duo Chat
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# GitLab Duo Chat

[Chat](../../user/gitlab_duo_chat.md) is a part of the [GitLab Duo](../../user/ai_features.md) offering.

How Chat describes itself: "I am GitLab Duo Chat, an AI assistant focused on helping developers with DevSecOps,
software development, source code, project management, CI/CD, and GitLab. Please feel free to engage me in these areas."

Chat can answer different questions and perform certain tasks. It's done with the help of [prompts](glossary.md) and [tools](#adding-a-new-tool).

To answer a user's question asked in the Chat interface, GitLab sends a [GraphQL request](https://gitlab.com/gitlab-org/gitlab/-/blob/4cfd0af35be922045499edb8114652ba96fcba63/ee/app/graphql/mutations/ai/action.rb) to the Rails backend.
Rails backend sends then instructions to the Large Language Model (LLM) via the [AI Gateway](../../architecture/blueprints/ai_gateway/index.md).

## Set up GitLab Duo Chat

There is a difference in the setup for Saas and self-managed instances.
We recommend to start with a process described for SaaS-only AI features.

1. [Setup SaaS-only AI features](index.md#saas-only-features).
1. [Setup self-managed AI features](index.md#local-setup).

## Working with GitLab Duo Chat

Prompts are the most vital part of GitLab Duo Chat system. Prompts are the instructions sent to the LLM to perform certain tasks.

The state of the prompts is the result of weeks of iteration. If you want to change any prompt in the current tool, you must put it behind a feature flag.

If you have any new or updated prompts, ask members of AI Framework team to review, because they have significant experience with them.

### Troubleshooting

When working with Chat locally, you might run into an error. Most commons problems are documented in this section.
If you find an undocumented issue, you should document it in this section after you find a solution.

| Problem                                                               | Solution                                                                                                                                                                                                                                                                              |
|-----------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| There is no Chat button in the GitLab UI.                             | Make sure your user is a part of a group with enabled Experimental and Beta features.                                                                                                                                                                                                 |
| Chat replies with "Forbidden by auth provider" error.                 | Backend can't access LLMs. Make sure your [AI Gateway](index.md#local-setup) is set up correctly.                                                                                                                                                                                      |
| Requests take too long to appear in UI                               | Consider restarting Sidekiq by running `gdk restart rails-background-jobs`. If that doesn't work, try `gdk kill` and then `gdk start`. Alternatively, you can bypass Sidekiq entirely. To do that temporary alter `Llm::CompletionWorker.perform_async` statements with `Llm::CompletionWorker.perform_inline` |
| There is no chat button in GitLab UI when GDK is running on non-SaaS mode | You do not have cloud connector access token record or seat assigned. To create cloud connector access record, in rails console put following code: `CloudConnector::Access.new(data: { available_services: [{ name: "duo_chat", serviceStartTime: ":date_in_the_future" }] }).save`. |

## Contributing to GitLab Duo Chat

From the code perspective, Chat is implemented in the similar fashion as other AI features. Read more about GitLab [AI Abstraction layer](index.md#feature-development-abstraction-layer).

The Chat feature uses a [zero-shot agent](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb) that includes a system prompt explaining how the large language model should interpret the question and provide an
answer. The system prompt defines available tools that can be used to gather
information to answer the user's question.

The zero-shot agent receives the user's question and decides which tools to use to gather information to answer it.
It then makes a request to the large language model, which decides if it can answer directly or if it needs to use one
of the defined tools.

The tools each have their own prompt that provides instructions to the large language model on how to use that tool to
gather information. The tools are designed to be self-sufficient and avoid multiple requests back and forth to
the large language model.

After the tools have gathered the required information, it is returned to the zero-shot agent, which asks the large language
model if enough information has been gathered to provide the final answer to the user's question.

### Adding a new tool

To add a new tool:

1. Create files for the tool in the `ee/lib/gitlab/llm/chain/tools/` folder. Use existing tools like `issue_identifier` or
   `resource_reader` as a template.

1. Write a class for the tool that includes:

    - Name and description of what the tool does
    - Example questions that would use this tool
    - Instructions for the large language model on how to use the tool to gather information - so the main prompts that
      this tool is using.

1. Test and iterate on the prompt using RSpec tests that make real requests to the large language model.
    - Prompts require trial and error, the non-deterministic nature of working with LLM can be surprising.
    - Anthropic provides good [guide](https://docs.anthropic.com/claude/docs/intro-to-prompting) on working on prompts.
    - GitLab [guide](prompts.md) on working with prompts.

1. Implement code in the tool to parse the response from the large language model and return it to the zero-shot agent.

1. Add the new tool name to the `tools` array in `ee/lib/gitlab/llm/completions/chat.rb` so the zero-shot agent knows about it.

1. Add tests by adding questions to the test-suite for which the new tool should respond to. Iterate on the prompts as needed.

The key things to keep in mind are properly instructing the large language model through prompts and tool descriptions,
keeping tools self-sufficient, and returning responses to the zero-shot agent. With some trial and error on prompts,
adding new tools can expand the capabilities of the Chat feature.

There are available short [videos](https://www.youtube.com/playlist?list=PL05JrBw4t0KoOK-bm_bwfHaOv-1cveh8i) covering this topic.

## Debugging

To gather more insights about the full request, use the `Gitlab::Llm::Logger` file to debug logs.
The default logging level on production is `INFO` and **must not** be used to log any data that could contain personal identifying information.

To follow the debugging messages related to the AI requests on the abstraction layer, you can use:

```shell
export LLM_DEBUG=1
gdk start
tail -f log/llm.log
```

## Tracing with LangSmith

Tracing is a powerful tool for understanding the behavior of your LLM application.
LangSmith has best-in-class tracing capabilities, and it's integrated with GitLab Duo Chat. Tracing can help you track down issues like:

- I'm new to GitLab Duo Chat and would like to understand what's going on under the hood.
- Where exactly the process failed when you got an unexpected answer.
- Which process was a bottle neck of the latency.
- What tool was used for an ambiguous question.

![LangSmith UI](img/langsmith.png)

Tracing is especially useful for evaluation that runs GitLab Duo Chat against large dataset.
LangSmith integration works with any tools, including [Prompt Library](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)
and [RSpec tests](#testing-gitlab-duo-chat).

### Use tracing with LangSmith

NOTE:
Tracing is available in Development and Testing environment only.
It's not available in Production environment.

1. Access to [LangSmith](https://smith.langchain.com/) site and create an account.
1. Create [an API key](https://docs.smith.langchain.com/#create-an-api-key).
1. Set the following environment variables in GDK. You can define it in `env.runit` or directly `export` in the terminal.

    ```shell
    export LANGCHAIN_TRACING_V2=true
    export LANGCHAIN_API_KEY='<your-api-key>'
    export LANGCHAIN_PROJECT='<your-project-name>'
    export LANGCHAIN_ENDPOINT='api.smith.langchain.com'
    export GITLAB_RAILS_RACK_TIMEOUT=180 # Extending puma timeout for using LangSmith with Prompt Library as the evaluation tool.
    ```

1. Restart GDK.

## Testing GitLab Duo Chat

Because the success of answers to user questions in GitLab Duo Chat heavily depends
on toolchain and prompts of each tool, it's common that even a minor change in a
prompt or a tool impacts processing of some questions.

To make sure that a change in the toolchain doesn't break existing
functionality, you can use the following RSpec tests to validate answers to some
predefined questions when using real LLMs:

1. `ee/spec/lib/gitlab/llm/completions/chat_real_requests_spec.rb`
   This test validates that the zero-shot agent is selecting the correct tools
   for a set of Chat questions. It checks on the tool selection but does not
   evaluate the quality of the Chat response.
1. `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb`
   This test evaluates the quality of a Chat response by passing the question
   asked along with the Chat-provided answer and context to at least two other
   LLMs for evaluation. This evaluation is limited to questions about issues and
   epics only. Learn more about the [GitLab Duo Chat QA Evaluation Test](#gitlab-duo-chat-qa-evaluation-test).

If you are working on any changes to the GitLab Duo Chat logic, be sure to run
the [GitLab Duo Chat CI jobs](#testing-with-ci) the merge request that contains
your changes. Some of the CI jobs must be [manually triggered](../../ci/jobs/job_control.md#run-a-manual-job).

## Testing locally

To run the QA Evaluation test locally, the following environment variables
must be exported:

```ruby
export VERTEX_AI_EMBEDDINGS='true' # if using Vertex embeddings
export ANTHROPIC_API_KEY='<key>' # can use dev value of Gitlab::CurrentSettings
export VERTEX_AI_CREDENTIALS='<vertex-ai-credentials>' # can set as dev value of Gitlab::CurrentSettings.vertex_ai_credentials
export VERTEX_AI_PROJECT='<vertex-project-name>' # can use dev value of Gitlab::CurrentSettings.vertex_ai_project

REAL_AI_REQUEST=1 bundle exec rspec ee/spec/lib/gitlab/llm/completions/chat_real_requests_spec.rb
```

When you update the test questions that require documentation embeddings,
make sure you [generate a new fixture](index.md#using-in-specs) and
commit it together with the change.

## Testing with CI

The following CI jobs for GitLab project run the tests tagged with `real_ai_request`:

- `rspec-ee unit gitlab-duo-chat-zeroshot`:
  the job runs `ee/spec/lib/gitlab/llm/completions/chat_real_requests_spec.rb`.
  The job must be manually triggered and is allowed to fail.

- `rspec-ee unit gitlab-duo-chat-qa`:
  The job runs the QA evaluation tests in
  `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb`.
  The job must be manually triggered and is allowed to fail.
  Read about [GitLab Duo Chat QA Evaluation Test](#gitlab-duo-chat-qa-evaluation-test).

- `rspec-ee unit gitlab-duo-chat-qa-fast`:
  The job runs a single QA evaluation test from `ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb`.
  The job is always run and not allowed to fail. Although there's a chance that the QA test still might fail,
  it is cheap and fast to run and intended to prevent a regression in the QA test helpers.

- `rspec-ee unit gitlab-duo pg14`:
  This job runs tests to ensure that the GitLab Duo features are functional without running into system errors.
  The job is always run and not allowed to fail.
  This job does NOT conduct evaluations. The quality of the feature is tested in the other jobs such as QA jobs.

### Management of credentials and API keys for CI jobs

All API keys required to run the rspecs should be [masked](../../ci/variables/index.md#mask-a-cicd-variable)

The exception is GCP credentials as they contain characters that prevent them from being masked.
Because the CI jobs need to run on MR branches, GCP credentials cannot be added as a protected variable
and must be added as a regular CI variable.
For security, the GCP credentials and the associated project added to
GitLab project's CI must not be able to access any production infrastructure and sandboxed.

### GitLab Duo Chat QA Evaluation Test

Evaluation of a natural language generation (NLG) system such as
GitLab Duo Chat is a rapidly evolving area with many unanswered questions and ambiguities.

A practical working assumption is LLMs can generate a reasonable answer when given a clear question and a context.
With the assumption, we are exploring using LLMs as evaluators
to determine the correctness of a sample of questions
to track the overall accuracy of GitLab Duo Chat's responses and detect regressions in the feature.

For the discussions related to the topic,
see [the merge request](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/431)
and [the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/427251).

The current QA evaluation test consists of the following components.

#### Epic and issue fixtures

The fixtures are the replicas of the _public_ issues and epics from projects and groups _owned by_ GitLab.
The internal notes were excluded when they were sampled. The fixtures have been commited into the canonical `gitlab` repository.
See [the snippet](https://gitlab.com/gitlab-org/gitlab/-/snippets/3613745) used to create the fixtures.

#### RSpec and helpers

1. [The RSpec file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/lib/gitlab/llm/chain/agents/zero_shot/qa_evaluation_spec.rb)
   and the included helpers invoke the Chat service, an internal interface with the question.

1. After collecting the Chat service's answer,
   the answer is injected into a prompt, also known as an "evaluation prompt", that instructs
   a LLM to grade the correctness of the answer based on the question and a context.
   The context is simply a JSON serialization of the issue or epic being asked about in each question.

1. The evaluation prompt is sent to two LLMs, Claude and Vertex.

1. The evaluation responses of the LLMs are saved as JSON files.

1. For each question, RSpec will regex-match for `CORRECT` or `INCORRECT`.

#### Collection and tracking of QA evaluation with CI/CD automation

The `gitlab` project's CI configurations have been setup to run the RSpec,
collect the evaluation response as artifacts and execute
[a reporter script](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/duo_chat/reporter.rb)
that automates collection and tracking of evaluations.

When `rspec-ee unit gitlab-duo-chat-qa` job runs in a pipeline for a merge request,
the reporter script uses the evaluations saved as CI artifacts
to generate a Markdown report and posts it as a note in the merge request.

To keep track of and compare QA test results over time, you must manually
run the `rspec-ee unit gitlab-duo-chat-qa` on the `master` the branch:

1. Visit the [new pipeline page](https://gitlab.com/gitlab-org/gitlab/-/pipelines/new).
1. Select "Run pipeline" to run a pipeline against the `master` branch
1. When the pipeline first starts, the `rspec-ee unit gitlab-duo-chat-qa` job under the
   "Test" stage will not be available. Wait a few minutes for other CI jobs to
   run and then manually kick off this job by selecting the "Play" icon.

When the test runs on `master`, the reporter script posts the generated report as an issue,
saves the evaluations artfacts as a snippet, and updates the tracking issue in
[`GitLab-org/ai-powered/ai-framework/qa-evaluation#1`](https://gitlab.com/gitlab-org/ai-powered/ai-framework/qa-evaluation/-/issues/1)
in the project [`GitLab-org/ai-powered/ai-framework/qa-evaluation`](<https://gitlab.com/gitlab-org/ai-powered/ai-framework/qa-evaluation>).

## GraphQL Subscription

The GraphQL Subscription for Chat behaves slightly different because it's user-centric. A user could have Chat open on multiple browser tabs, or also on their IDE.
We therefore need to broadcast messages to multiple clients to keep them in sync. The `aiAction` mutation with the `chat` action behaves the following:

1. All complete Chat messages (including messages from the user) are broadcasted with the `userId`, `aiAction: "chat"` as identifier.
1. Chunks from streamed Chat messages and currently used tools are broadcasted with the `userId`, `resourceId`, and the `clientSubscriptionId` from the mutation as identifier.

Note that we still broadcast chat messages and currently used tools using the `userId` and `resourceId` as identifier.
However, this is deprecated and should no longer be used. We want to remove `resourceId` on the subscription as part of [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/420296).

## Testing GitLab Duo Chat in production-like environments

GitLab Duo Chat is enabled in the [Staging](https://staging.gitlab.com) and
[Staging Ref](https://staging-ref.gitlab.com/) GitLab environments.

Because GitLab Duo Chat is currently only available to members of groups in the
Premium and Ultimate tiers, Staging Ref may be an easier place to test changes as a GitLab
team member because
[you can make yourself an instance Admin in Staging Ref](https://handbook.gitlab.com/handbook/engineering/infrastructure/environments/staging-ref/#admin-access)
and, as an Admin, easily create licensed groups for testing.

## Product Analysis

To better understand how the feature is used, each production user input message is analyzed using LLM and Ruby,
and the analysis is tracked as a Snowplow event.

The analysis can contain any of the attributes defined in the latest [iglu schema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/ai_question_category/jsonschema).

- All possible "category" and "detailed_category" are listed [here](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/fixtures/categories.xml).
- The following is yet to be implemented:
  - "is_proper_sentence"
- The following are deprecated:
  - "number_of_questions_in_history"
  - "length_of_questions_in_history"
  - "time_since_first_question"

[Dashboards](https://handbook.gitlab.com/handbook/engineering/development/data-science/duo-chat/#-dashboards-internal-only) can be created to visualize the collected data.

## How `access_duo_chat` policy works

This table describes the requirements for the `access_duo_chat` policy to
return `true` in different contexts.

| | GitLab.com | Dedicated or Self-managed | All instances |
|----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------|
| for user outside of project or group (`user.can?(:access_duo_chat)`)  | User need to belong to at least one group on Premium or Ultimate tier with `experiment_and_beta_features` group setting switched on | - Instance needs to be on Premium or Ultimate tier<br>- Instance needs to have `instance_level_ai_beta_features_enabled` setting switched on |  |
| for user in group context (`user.can?(:access_duo_chat, group)`)     | - User needs to belong to at least one group on Premium or Ultimate tier with `experiment_and_beta_features` group setting switched on<br>- Root ancestor group of the group needs to be on Premium or Ultimate tier and have `experiment_and_beta_features` setting switched on | - Instance needs to be on Premium or Ultimate tier<br>- Instance needs to have `instance_level_ai_beta_features_enabled` setting switched on | User must have at least _read_ permissions on the group |
| for user in project context (`user.can?(:access_duo_chat, project)`) | - User needs to belong to at least one group on the Premium or Ultimate tier with `experiment_and_beta_features` group setting enabled<br>- Project root ancestor group needs to be on Premium or Ultimate tier and have `experiment_and_beta_features` group setting switched on | - Instance need to be on Ultimate tier<br>- Instance needs to have `instance_level_ai_beta_features_enabled` setting switched on | User must to have at least _read_ permission on the project |

## Running GitLab Duo Chat prompt experiments

Before being merged, all prompt or model changes for GitLab Duo Chat should both:

1. Be behind a feature flag *and*
1. Be evaluated locally

The type of local evaluation needed depends on the type of change. GitLab Duo
Chat local evaluation using the Prompt Library is an effective way of measuring
average correctness of responses to questions about issues and epics.

Follow the
[Prompt Library guide](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/how-to/run_duo_chat_eval.md#configuring-duo-chat-with-local-gdk)
to evaluate GitLab Duo Chat changes locally. The prompt library documentation is
the single source of truth and should be the most up-to-date.

Please, see the video ([internal link](https://drive.google.com/file/d/1X6CARf0gebFYX4Rc9ULhcfq9LLLnJ_O-)) that covers the full setup.

## How a Chat prompt is constructed

All Chat requests are resolved with the GitLab GraphQL API. And, for now,
prompts for 3rd party LLMs are hard-coded into the GitLab codebase.

But if you want to make a change to a Chat prompt, it isn't as obvious as
finding the string in a single file. Chat prompt construction is hard to follow
because the prompt is put together over the course of many steps. Here is the
flow of how we construct a Chat prompt:

1. API request is made to the GraphQL AI Mutation; request contains user Chat
   input.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/graphql/mutations/ai/action.rb#L6))
1. GraphQL mutation calls `Llm::ExecuteMethodService#execute`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/graphql/mutations/ai/action.rb#L43))
1. `Llm::ExecuteMethodService#execute` sees that the `chat` method was sent to
   the GraphQL API and calls `Llm::ChatService#execute`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/services/llm/execute_method_service.rb#L36))
1. `Llm::ChatService#execute` calls `schedule_completion_worker`, which is
   defined in `Llm::BaseService` (the base class for `ChatService`)
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/services/llm/base_service.rb#L72-87))
1. `schedule_completion_worker` calls `Llm::CompletionWorker.perform_for`, which
   asynchronously enqueues the job
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/workers/llm/completion_worker.rb#L33))
1. `Llm::CompletionWorker#perform` is called when the job runs. It deserializes
   the user input and other message context and passes that over to
   `Llm::Internal::CompletionService#execute`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/676cca2ea68d87bcfcca02a148c354b0e4eabc97/ee/app/workers/llm/completion_worker.rb#L44))
1. `Llm::Internal::CompletionService#execute` calls
   `Gitlab::Llm::CompletionsFactory#completion!`, which pulls the `ai_action`
   from original GraphQL request and initializes a new instance of
   `Gitlab::Llm::Completions::Chat` and calls `execute` on it
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/55b8eb6ff869e61500c839074f080979cc60f9de/ee/lib/gitlab/llm/completions_factory.rb#L89))
1. `Gitlab::Llm::Completions::Chat#execute` calls `Gitlab::Llm::Chain::Agents::ZeroShot::Executor`.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/d539f64ce6c5bed72ab65294da3bcebdc43f68c6/ee/lib/gitlab/llm/completions/chat.rb#L128-134))
1. `Gitlab::Llm::Chain::Agents::ZeroShot::Executor#execute` calls
   `execute_streamed_request`, which calls `request`, a method defined in the
   `AiDependent` concern
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/d539f64ce6c5bed72ab65294da3bcebdc43f68c6/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb#L85))
1. (`*`) `AiDependent#request` pulls the base prompt from `provider_prompt_class.prompt`.
   For Chat, the provider prompt class is `ZeroShot::Prompts::Anthropic`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/4eb4ce67ccc0fe331ddcce3fcc53e0ec0f47cd76/ee/lib/gitlab/llm/chain/concerns/ai_dependent.rb#L44-46))
1. (`*`) `ZeroShot::Prompts::Anthropic.prompt` pulls a base prompt and formats
   it in the way that Anthropic expects it for the
   [Text Completions API](https://docs.anthropic.com/claude/reference/complete_post)
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/4eb4ce67ccc0fe331ddcce3fcc53e0ec0f47cd76/ee/lib/gitlab/llm/chain/agents/zero_shot/prompts/anthropic.rb#L13-24))
1. (`*`) As part of constructing the prompt for Anthropic,
   `ZeroShot::Prompts::Anthropic.prompt` makes a call to the `base_prompt` class
   method, which is defined in `ZeroShot::Prompts::Base`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/4eb4ce67ccc0fe331ddcce3fcc53e0ec0f47cd76/ee/lib/gitlab/llm/chain/agents/zero_shot/prompts/base.rb#L10-19))
1. (`*`) `ZeroShot::Prompts::Base.base_prompt` calls
   `Utils::Prompt.no_role_text` and passes `prompt_version` to the method call.
   The `prompt_version` option resolves to `PROMPT_TEMPLATE` from
   `ZeroShot::Executor`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb#L143))
1. (`*`) `PROMPT_TEMPLATE` is where the tools available and definitions for each
   tool are interpolated into the zero shot prompt using the `format` method.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb#L200-237)
1. (`*`) The `PROMPT_TEMPLATE` is interpolated into the `default_system_prompt`,
   defined
   [(here)](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/utils/prompt.rb#L54-73)
   in the `ZeroShot::Prompts::Base.base_prompt` method call, and that whole big
   prompt string is sent to `ai_request.request`
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/concerns/ai_dependent.rb#L19))
1. `ai_request` is defined in `Llm::Completions::Chat` and evaluates to either
   `AiGateway` or `Anthropic` depending on the presence of a feature flag. On
   production, we use `AiGateway` so this documentation follows that codepath.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/3cd5e5bb3059d6aa9505d21a59cba57fec356473/ee/lib/gitlab/llm/completions/chat.rb#L42)
1. `ai_request.request` routes to `Llm::Chain::Requests::AiGateway#request`,
   which calls `ai_client.stream`
  ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/requests/ai_gateway.rb#L20-27))
1. `ai_client.stream` routes to `Gitlab::Llm::AiGateway::Client#stream`, which
   makes an API request to the AI Gateway `/v1/chat/completion` endpoint
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/ai_gateway/client.rb#L64-82))
1. We've now made our first request to the AI Gateway. If the LLM says that the
   answer to the first request is a final answer, we
   [parse the answer](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/parsers/chain_of_thought_parser.rb)
   and return it ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb#L47))
1. (`*`) If the first answer is not final, the "thoughts" and "picked tools"
   from the first LLM request are parsed and then the relevant tool class is
   called.
   ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/e88256b1acc0d70ffc643efab99cad9190529312/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb#L56-65))
1. The tool executor classes also include `Concerns::AiDependent` and use the
   included `request` method similar to how `ZeroShot::Executor` does
  ([example](https://gitlab.com/gitlab-org/gitlab/-/blob/70fca6dbec522cb2218c5dcee66caa908c84271d/ee/lib/gitlab/llm/chain/tools/identifier.rb#L8)).
   The `request` method uses the same `ai_request` instance
   that was injected into the `context` in `Llm::Completions::Chat`. For Chat,
   this is `Gitlab::Llm::Chain::Requests::AiGateway`. So, essentially the same
   request to the AI Gateway is put together but with a different
   `prompt` / `PROMPT_TEMPLATE` than for the first request
   ([Example tool prompt template](https://gitlab.com/gitlab-org/gitlab/-/blob/70fca6dbec522cb2218c5dcee66caa908c84271d/ee/lib/gitlab/llm/chain/tools/issue_identifier/executor.rb#L39-104))
1. If the tool answer is not final, the response is added to `agent_scratchpad`
   and the loop in `ZeroShot::Executor` starts again, adding the additional
   context to the request. It loops to up to 10 times until a final answer is reached.

(`*`) indicates that this step is part of the actual construction of the prompt
