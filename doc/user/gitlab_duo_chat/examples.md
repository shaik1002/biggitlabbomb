---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Ask GitLab Duo Chat

GitLab Duo Chat can help with a variety of questions. The following examples
represent some of the areas where GitLab Duo Chat can be the most helpful.

For additional practical examples, see the [GitLab Duo use cases](../gitlab_duo/use_cases.md).

## Ask about GitLab

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** GitLab UI, Web IDE, VS Code, and JetBrains IDEs
**LLMs:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet), [Vertex AI Search](https://cloud.google.com/enterprise-search)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695) for GitLab.com in GitLab 16.0.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/451215) ability to ask doc-related questions on self-managed in GitLab 17.0 [with a flag](../../administration/feature_flags.md) named `ai_gateway_docs_search`. Enabled by default.
> - [Generally available and feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154876) in GitLab 17.1.

You can ask questions about how GitLab works. Things like:

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`

GitLab Duo Chat uses the GitLab documentation as source. To keep Chat up to date with the documentation,
its knowledge base is updated daily.

- On GitLab.com the, the most recent version of the documentation is used.
- On Self-managed and GitLab Dedicated, the documentation for the version of the instance is used.

## Ask about a specific issue

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** GitLab UI, Web IDE, VS Code, JetBrains IDEs
**LLM:** Anthropic [Claude 3 Haiku](https://docs.anthropic.com/en/docs/models-overview#claude-3-a-new-generation-of-ai)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for GitLab.com in GitLab 16.0.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for self-managed and GitLab Dedicated in GitLab 16.8.

You can ask about a specific GitLab issue. For example:

- `Generate a summary for the issue identified via this link: <link to your issue>`
- When you are viewing an issue in GitLab, you can ask `Generate a concise summary of the current issue.`
- `How can I improve the description of <link to your issue> so that readers understand the value and problems to be solved?`

NOTE:
If the issue contains a large amount of text (more than 40,000 words), GitLab Duo Chat might not be able to consider every word. The AI model has a limit to the amount of input it can process at one time.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For tips on how GitLab Duo Chat can improve your productivity with issues and epics, see [Boost your productivity with GitLab Duo Chat](https://youtu.be/RJezT5_V6dI).
<!-- Video published on 2024-04-17 -->

## Ask about a specific epic

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** GitLab UI, Web IDE, VS Code, JetBrains IDEs
**LLM:** Anthropic [Claude 3 Haiku](https://docs.anthropic.com/en/docs/models-overview#claude-3-a-new-generation-of-ai)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487) for GitLab.com in GitLab 16.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487) for self-managed and GitLab Dedicated in GitLab 16.8.

You can ask about a specific GitLab epic. For example:

- `Generate a summary for the epic identified via this link: <link to your epic>`
- When you are viewing an epic in GitLab, you can ask `Generate a concise summary of the opened epic.`
- `What are the unique use cases raised by commenters in <link to your epic>?`

NOTE:
If the epic contains a large amount of text (more than 40,000 words), GitLab Duo Chat might not be able to consider every word. The AI model has a limit to the amount of input it can process at one time.

## Explain selected code

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** GitLab UI, Web IDE, VS Code, JetBrains IDEs
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for GitLab.com in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed and GitLab Dedicated in GitLab 16.8.

You can ask GitLab Duo Chat to explain selected code:

1. Select some code in your IDE.
1. In Duo Chat, type `/explain`.

   ![Selecting code and asking GitLab Duo Chat to explain using the /explain slash command.](img/code_selection_duo_chat.png)

You can also add additional instructions to be considered. For example:

- `/explain the performance`
- `/explain focus on the algorithm`
- `/explain the performance gains or losses using this code`
- `/explain the object inheritance` (classes, object-oriented)
- `/explain why a static variable is used here` (C++)
- `/explain how this function would cause a segmentation fault` (C)
- `/explain how concurrency works in this context` (Go)
- `/explain how the request reaches the client` (REST API, database)

For more information, see [Use GitLab Duo Chat in VS Code](index.md#use-gitlab-duo-chat-in-vs-code).

In the GitLab UI, you can also explain code in:

- A [file](../project/repository/code_explain.md).
- A [merge request](../project/merge_requests/changes.md#explain-code-in-a-merge-request).

## Ask about or generate code

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** GitLab UI, Web IDE, VS Code, JetBrains IDEs
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for GitLab.com in GitLab 16.1.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for self-managed and GitLab Dedicated in GitLab 16.8.

You can ask GitLab Duo Chat questions about code by pasting that code into
the Duo Chat window. For example:

```plaintext
Provide a clear explanation of this Ruby code: def sum(a, b) a + b end.
Describe what this code does and how it works.
```

You can also ask Chat to generate code. For example:

- `Write a Ruby function that prints 'Hello, World!' when called.`
- `Develop a JavaScript program that simulates a two-player Tic-Tac-Toe game. Provide both game logic and user interface, if applicable.`
- `Create a regular expression for parsing IPv4 and IPv6 addresses in Python.`
- `Generate code for parsing a syslog log file in Java. Use regular expressions when possible, and store the results in a hash map.`
- `Create a product-consumer example with threads and shared memory in C++. Use atomic locks when possible.`
- `Generate Rust code for high performance gRPC calls. Provide a source code example for a server and client.`

## Ask follow up questions

You can ask follow-up questions to delve deeper into the topic or task at hand.
This helps you get more detailed and precise responses tailored to your specific needs,
whether it's for further clarification, elaboration, or additional assistance.

A follow-up to the question `Write a Ruby function that prints 'Hello, World!' when called` could be:

- `Can you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

A follow-up to the question `How to start a C# project?` could be:

- `Can you also please explain how to add a .gitignore and .gitlab-ci.yml file for C#?`

## Ask about errors

Programming languages that require compiling the source code may throw cryptic error messages. Similarly, a script or a web application could throw a stack trace. You can ask GitLab Duo Chat by prefixing the copied error message with, for example, `Please explain this error message:`. Add the specific context, like the programming language.

- `Explain this error message in Java: Int and system cannot be resolved to a type`
- `Explain when this C function would cause a segmentation fault: sqlite3_prepare_v2()`
- `Explain what would cause this error in Python: ValueError: invalid literal for int()`
- `Why is "this" undefined in VueJS? Provide common error cases, and explain how to avoid them.`
- `How to debug a Ruby on Rails stacktrace? Share common strategies and an example exception.`

## Refactor code in the IDE

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limted time, Premium or Ultimate. In the future, Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** Web IDE, VS Code, JetBrains IDEs
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for GitLab.com in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed and GitLab Dedicated in GitLab 16.8.

You can ask GitLab Duo Chat to refactor selected code:

1. Select some code in your IDE.
1. In Duo Chat, type `/refactor`.

You can include additional instructions to be considered. For example:

- Use a specific coding pattern, for example `/refactor with ActiveRecord` or `/refactor into a class providing static functions`.
- Use a specific library, for example `/refactor using mysql`.
- Use a specific function/algorithm, for example `/refactor into a stringstream with multiple lines` in C++.
- Refactor to a different programming language, for example `/refactor to TypeScript`.
- Focus on performance, for example `/refactor improving performance`.
- Focus on potential vulnerabilities, for example `/refactor avoiding memory leaks and exploits`.

## Fix code in the IDE

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** Web IDE, VS Code, JetBrains IDEs
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for GitLab.com, self-managed and GitLab Dedicated in GitLab 17.3.

You can ask GitLab Duo Chat to fix selected code:

1. Select some code in your IDE.
1. In Duo Chat, type `/fix`.

You can include additional instructions to be considered. For example:

- Focus on grammar and typos, for example, `/fix grammar mistakes and typos`.
- Focus on a concrete algorithm or problem description, for example, `/fix duplicate database inserts` or `/fix race conditions`.
- Focus on potential bugs that are not directly visible, for example, `/fix potential bugs`.
- Focus on code performance problems, for example, `/fix performance problems`.
- Focus on fixing the build when the code does not compile, for example, `/fix the build`.

## Write tests in the IDE

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** Web IDE, VS Code, JetBrains IDEs
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for GitLab.com in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed and GitLab Dedicated in GitLab 16.8.

You can ask GitLab Duo Chat to create tests for the selected code:

1. Select some code in your IDE.
1. In Duo Chat, type `/tests`.

You can include additional instructions to be considered. For example:

- Use a specific test framework, for example `/tests using the Boost.test framework` (C++) or `/tests using Jest` (JavaScript).
- Focus on extreme test cases, for example `/tests focus on extreme cases, force regression testing`.
- Focus on performance, for example `/tests focus on performance`.
- Focus on regressions and potential exploits, for example `/tests focus on regressions and potential exploits`.

For more information, see [Use GitLab Duo Chat in VS Code](index.md#use-gitlab-duo-chat-in-vs-code).

## Ask about CI/CD

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** GitLab UI, Web IDE, VS Code, JetBrains IDEs
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423524) for GitLab.com in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423524) for self-managed and GitLab Dedicated in GitLab 16.8.
> - [Updated LLM](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149619) from Claude 2.1 to Claude 3 Sonnet in GitLab 17.2.
> - [Updated LLM](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157696) from Claude 3 Sonnet to Claude 3.5 Sonnet in GitLab 17.2.

You can ask GitLab Duo Chat to create a CI/CD configuration:

- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`
- `Create a CI/CD configuration for building and linting a Python application.`
- `Create a CI/CD configuration to build and test Rust code.`
- `Create a CI/CD configuration for C++. Use gcc as compiler, and cmake as build tool.`
- `Create a CI/CD configuration for VueJS. Use npm, and add SAST security scanning.`
- `Generate a security scanning pipeline configuration, optimized for Java.`

You can also ask to explain specific job errors by copy-pasting the error message, prefixed with `Please explain this CI/CD job error message, in the context of <language>:`:

- `Please explain this CI/CD job error message in the context of a Go project: build.sh: line 14: go command not found`

Alternatively, you can use GitLab Duo Root Cause Analysis to [troubleshoot failed CI/CD jobs](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis).

## Troubleshoot failed CI/CD jobs with Root Cause Analysis

DETAILS:
**Tier:** For a limited time, Ultimate. In the future, Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** GitLab UI
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123692) in GitLab 16.2 as an [experiment](../../policy/experiment-beta-support.md#experiment) on GitLab.com.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/441681) and moved to GitLab Duo Chat in GitLab 17.3.

You can ask GitLab Duo Chat to determine the root cause of a CI/CD job failure by analyzing the logs.

Prerequisites:

- Have permission to view the CI/CD job.
- Have a paid GitLab Duo Enterprise seat.

To troubleshoot a failed CI/CD job:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Jobs**.
1. Select the failed CI/CD job.
1. From the job log page, do one of the following:

   - Below the job log, select **Troubleshoot**.
   - Open GitLab Duo Chat and type `/troubleshoot`.

An analysis of the reasons for the failure and an example fix is displayed.

## Explain a vulnerability

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Ultimate. In the future, Ultimate with [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Editors:** GitLab UI
**LLM:** Anthropic [Claude 3 Haiku](https://docs.anthropic.com/en/docs/about-claude/models#claude-3-a-new-generation-of-ai)

You can ask GitLab Duo Chat to explain a vulnerability when you are viewing a SAST vulnerability report.

For more information, see [Explaining a vulnerability](../application_security/vulnerabilities/index.md#explaining-a-vulnerability).

## Delete or reset the conversation

To delete all conversations permanently and clear the chat window:

- In the text box, type `/clear` and select **Send**.

To start a new conversation, but keep the previous conversations visible in the chat window:

- In the text box, type `/reset` and select **Send**.

In both cases, the conversation history will not be considered when you ask new questions.
Deleting or resetting might help improve the answers when you switch contexts, because Duo Chat will not get confused by the unrelated conversations.

## Supported slash commands

Duo Chat has a list of supported commands, each of which is preceded by a slash (`/`).
Use the following commands to quickly accomplish specific tasks.

| Command                | Purpose                                                                             |
|------------------------|-------------------------------------------------------------------------------------|
| /clear                 | [Delete all conversations permanently and clear the chat window](#delete-or-reset-the-conversation)  |
| /reset                 | [Start a new conversation, but keep the previous conversations visible in the chat window](#delete-or-reset-the-conversation)  |
| /tests                 | [Write tests](#write-tests-in-the-ide)                                              |
| /explain               | [Explain code](#explain-selected-code)              |
| /vulnerability_explain | [Explain current vulnerability](../application_security/vulnerabilities/index.md#explaining-a-vulnerability)   |
| /refactor              | [Refactor the code](#refactor-code-in-the-ide)        |
| /troubleshoot          | [Troubleshoot failed CI/CD jobs with Root Cause Analysis](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) |
| /fix                   | [Fix the code](#fix-code-in-the-ide)        |
