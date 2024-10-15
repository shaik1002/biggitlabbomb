---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Repository X-Ray

DETAILS:
**Tier:** Premium or Ultimate with [GitLab Duo Pro](../../../../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com, Self-managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12060) in GitLab 16.7.

Repository X-Ray enhances [GitLab Duo Code Suggestions](index.md) by providing additional context to improve the accuracy and relevance of code recommendations.

Repository X-Ray gives the code assistant more insight into the project's codebase and dependencies to generate better code suggestions. It does this by analyzing key project configuration files such as `Gemfile.lock`, `package.json`, and `go.mod` to build additional context.

By understanding the frameworks, libraries and other dependencies in use, Repository X-Ray helps the code assistant tailor suggestions to match the coding patterns, styles and technologies used in the project. This results in code recommendations that integrate more seamlessly and follow best practices for that stack.

## Supported languages and package managers

| Language   | Package Manager | Configuration File   |
| ---------- |-----------------| -------------------- |
| Go         | Go Modules      | `go.mod`             |
| JavaScript | NPM, Yarn       | `package.json`       |
| Ruby       | RubyGems        | `Gemfile.lock`       |
| Python     | Poetry          | `pyproject.toml`     |
| Python     | Pip             | `requirements.txt`   |
| Python     | Conda           | `environment.yml`    |
| PHP        | Composer        | `composer.json`      |
| Java       | Maven           | `pom.xml`            |
| Java       | Gradle          | `build.gradle`       |
| Kotlin     | Gradle          | `build.gradle.kts`   |
| C#         | NuGet           | `*.csproj`           |
| C/C++      | Conan           | `conanfile.txt`      |
| C/C++      | Conan           | `conanfile.py`       |
| C/C++      | vcpkg           | `vcpkg.json`         |

## Enable Repository X-Ray

Prerequisites:

- You must have access to [GitLab Duo Code Suggestions](index.md) in the project.
- GitLab Runner must be set up and enabled for the project, because Repository X-Ray runs analysis pipelines using GitLab runners.

To enable Repository X-Ray, add the following definition job to the project's `.gitlab-ci.yml`.

```yaml
xray:
  stage: build
  image: registry.gitlab.com/gitlab-org/code-creation/repository-x-ray:latest
  allow_failure: true
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    OUTPUT_DIR: reports
  script:
    - x-ray-scan -p "$CI_PROJECT_DIR" -o "$OUTPUT_DIR"
  artifacts:
    reports:
      repository_xray: "$OUTPUT_DIR/*/*.json"
```

- The `$OUTPUT_DIR` environment variable defines the:
  - Output directory for reports.
  - Path that artifacts are uploaded from.
- The added rules restrict the job to the default branch only. Restricting the job this way ensures development changes do not impact the baseline X-Ray data used for production code suggestions.

After the initial x-ray job completes and uploads the repository analysis reports, no further action is required. Repository X-Ray automatically enriches all code generation requests from that point forward.

The X-Ray data for your project updates each time a CI/CD pipeline containing the `xray`
job is run. To learn more about pipeline configuration and triggers, see the
[pipelines documentation](../../../../ci/pipelines/merge_request_pipelines.md).
