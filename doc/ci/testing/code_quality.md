---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Quality

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Code Quality helps code authors find and fix problems faster, and frees up time for code reviewers to focus their attention on more nuanced suggestions or comments.

When you use Code Quality in your CI/CD pipelines, you can avoid merging changes that would degrade your code's quality or deviate from your organization's standards.

## Features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Feature                                                                                     | In Free                | In Premium             | In Ultimate            |
|:--------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|:-----------------------|
| [Import Code Quality results from CI/CD jobs](#import-code-quality-results-from-a-cicd-job) | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| [Use CodeClimate-based scanning](#use-the-built-in-code-quality-cicd-template-deprecated)   | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| [See findings in a merge request widget](#merge-request-widget)                             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| [See findings in a pipeline report](#pipeline-details-view)                                 | **{dotted-circle}** No | **{check-circle}** Yes | **{check-circle}** Yes |
| [See findings in the merge request changes view](#merge-request-changes-view)               | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes |
| [Analyze overall health in a project quality summary view](#project-quality-view)           | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes |

## Scan code for quality violations

Code Quality is an open system that supports importing results from many scanning tools.
To find violations and surface them, you can:

- Directly use a scanning tool and [import its results](#import-code-quality-results-from-a-cicd-job). _(Preferred.)_
- [Use a built-in CI/CD template](#use-the-built-in-code-quality-cicd-template-deprecated) to enable scanning. The template uses the CodeClimate engine, which wraps common open source tools. _(Deprecated.)_

You can also [integrate multiple tools](#integrate-multiple-tools).

### Import Code Quality results from a CI/CD job

Many development teams already use linters, style checkers, or other tools in their CI/CD pipelines to automatically detect violations of coding standards.
You can make the findings from these tools easier to see and fix by integrating them with Code Quality.

To integrate a tool with Code Quality:

1. Add the tool to your CI/CD pipeline.
1. Configure the tool to output a report as a file.
   - This file must use a [specific JSON format](#code-quality-report-format).
   - Many tools support this output format natively. They may call it a "CodeClimate report", "GitLab Code Quality report", or another similar name.
   - Other tools can sometimes create JSON output using a custom JSON format or template. Because the [report format](#code-quality-report-format) has only a few required fields, you may be able to use this output type to create a report for Code Quality.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that matches this file.

Now, after the pipeline runs, the quality tool's results are [processed and displayed](#view-code-quality-results).

### Use the built-in Code Quality CI/CD template (deprecated)

WARNING:
This feature was [deprecated](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed) in GitLab 17.3 and is planned for removal in 18.0.
[Integrate the results from a supported tool directly](#import-code-quality-results-from-a-cicd-job) instead.

Code Quality also includes a built-in CI/CD template, `Code-Quality.gitlab-ci.yaml`.
This template runs a scan based on the open source CodeClimate scanning engine.

The CodeClimate engine runs:

- Basic maintainability checks for a [set of supported languages](https://docs.codeclimate.com/docs/supported-languages-for-maintainability).
- A configurable set of [plugins](https://docs.codeclimate.com/docs/list-of-engines), which wrap open source scanners, to analyze your source code.

For more details, see [Configure CodeClimate-based Code Quality scanning](code_quality_codeclimate_scanning.md).

### Integrate multiple tools

You can capture results from multiple tools in a single pipeline.
For example, you can run a code linter to scan your code along with a language linter to scan your documentation, or you can use a standalone tool along with CodeClimate-based scanning.
Code Quality combines all of the reports so you see all of them when you [view results](#view-code-quality-results).

Here is an example that returns ESLint output in the necessary format:

```yaml
eslint:
  image: node:18-alpine
  script:
    - npm ci
    - npx eslint --format gitlab .
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
```

## View Code Quality results

Code Quality results are shown in the:

- [Merge request widget](#merge-request-widget)
- [Merge request changes view](#merge-request-changes-view)
- [Pipeline details view](#pipeline-details-view)
- [Project quality view](#project-quality-view)

### Merge request widget

Code Quality analysis results display in the merge request widget area if a report from the target
branch is available for comparison. The merge request widget displays Code Quality findings and resolutions that
were introduced by the changes made in the merge request. Multiple Code Quality findings with identical
fingerprints display as a single entry in the merge request widget. Each individual finding is available in the
full report available in the **Pipeline** details view.

![Code Quality Widget](img/code_quality_widget_v13_11.png)

### Merge request changes view

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Code Quality results display in the merge request **Changes** view. Lines containing Code Quality
issues are marked by a symbol beside the gutter. Select the symbol to see the list of issues, then select an issue to see its details.

![Code Quality Inline Indicator](img/code_quality_inline_indicator_v16_7.png)

### Pipeline details view

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The full list of Code Quality violations generated by a pipeline is shown in the **Code Quality**
tab of the pipeline's details page. The pipeline details view displays all Code Quality findings
that were found on the branch it was run on.

![Code Quality Report](img/code_quality_report_v13_11.png)

### Project quality view

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72724) in GitLab 14.5 [with a flag](../../administration/feature_flags.md) named `project_quality_summary_page`. This feature is in [beta](../../policy/experiment-beta-support.md). Disabled by default.

The project quality view displays an overview of the code quality findings. The view can be found under **Analyze > CI/CD analytics**, and requires [`project_quality_summary_page`](../../user/feature_flags.md) feature flag to be enabled for this particular project.

![Code Quality Summary](img/code_quality_summary_v15_9.png)

## Code Quality report format

You can [import Code Quality results](#import-code-quality-results-from-a-cicd-job) from any tool that can output a report in the following format.
This format is a version of the [CodeClimate report format](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) that includes a smaller number of fields.

The file you provide as [Code Quality report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) must contain a single JSON array.
Each object in that array must have at least the following properties:

| Name                                                      | Description                                                                                            | Type                                                                         |
|-----------------------------------------------------------|--------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| `description`                                             | A human-readable description of the code quality violation.                                            | String                                                                       |
| `check_name`                                              | A unique name representing the check, or rule, associated with this violation.                         | String                                                                       |
| `fingerprint`                                             | A unique fingerprint to identify this specific code quality violation, such as a hash of its contents. | String                                                                       |
| `severity`                                                | The severity of the violation.                                                                         | String. Valid values are `info`, `minor`, `major`, `critical`, or `blocker`. |
| `location.path`                                           | The file containing the code quality violation, expressed as a relative path in the repository.        | String                                                                       |
| `location.lines.begin` or `location.positions.begin.line` | The line on which the code quality violation occurred.                                                 | Integer                                                                      |

The format is different from the [CodeClimate report format](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) in the following ways:

- Although the [CodeClimate report format](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) supports more properties, Code Quality only processes the fields listed above.
- The GitLab parser does not allow a [byte order mark](https://en.wikipedia.org/wiki/Byte_order_mark) at the beginning of the file.

For example, this is a compliant report:

```json
[
  {
    "description": "'unused' is assigned a value but never used.",
    "check_name": "no-unused-vars",
    "fingerprint": "7815696ecbf1c96e6894b779456d330e",
    "severity": "minor",
    "location": {
      "path": "lib/index.js",
      "lines": {
        "begin": 42
      }
    }
  }
]
```
