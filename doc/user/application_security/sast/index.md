---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Static Application Security Testing (SAST)

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

NOTE:
The whitepaper ["A Seismic Shift in Application Security"](https://about.gitlab.com/resources/whitepaper-seismic-shift-application-security/)
explains how 4 of the top 6 attacks were application based. Download it to learn how to protect your
organization.

If you're using [GitLab CI/CD](../../../ci/index.md), you can use Static Application Security
Testing (SAST) to check your source code for known vulnerabilities. You can run SAST analyzers in
any GitLab tier. The analyzers output JSON-formatted reports as job artifacts.

With GitLab Ultimate, SAST results are also processed so you can:

- Use them in approval workflows.
- Review them in the security dashboard.

For more details, see the [Summary of features per tier](#summary-of-features-per-tier).

![SAST results shown in the MR widget](img/sast_results_in_mr_v14_0.png)

A pipeline consists of multiple jobs, including SAST and DAST scanning. If any job fails to finish
for any reason, the security dashboard does not show SAST scanner output. For example, if the SAST
job finishes but the DAST job fails, the security dashboard does not show SAST results. On failure,
the analyzer outputs an [exit code](../../../development/integrations/secure.md#exit-code).

## Requirements

SAST runs in the `test` stage, which is available by default. If you redefine the stages in the `.gitlab-ci.yml` file, the `test` stage is required.

To run SAST jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using SaaS runners on GitLab.com, this is enabled by default.

NOTE:
GitLab SAST analyzers only run in a Docker on Linux amd64 environment, which is **not** `Docker 19.03.0`. See [Docker error](troubleshooting.md#docker-error) for details.

## Supported languages and frameworks

GitLab SAST supports scanning a variety of programming languages and frameworks.
Once you [enable SAST](#configuration), the right set of analyzers runs automatically even if your project uses more than one language.

For more information about our plans for language support in SAST, see the [category direction page](https://about.gitlab.com/direction/secure/static-analysis/sast/#language-support).

| Language / framework         | [Analyzer](analyzers.md) used for scanning                                                                   | Minimum supported GitLab version                                                        |
|------------------------------|--------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| .NET (all versions, C# only) | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 15.4                                                                                    |
| Apex (Salesforce)            | [PMD](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex)                                    | 12.1                                                                                    |
| C                            | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 14.2                                                                                    |
| C/C++                        | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)                           | 16.11                                                                                    |
| Elixir (Phoenix)             | [Sobelow](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)                                 | 11.1                                                                                    |
| Go                           | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 14.4                                                                                    |
| Groovy<sup>1</sup>           | [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) with the find-sec-bugs plugin | 11.3 (Gradle) & 11.9 (Maven, SBT)                                                       |
| Helm Charts                  | [Kubesec](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)                                 | 13.1                                                                                    |
| Java (any build system)      | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 14.10                                                                                   |
| Java (Android)               | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)                              | 16.11                                                                                    |
| JavaScript                   | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 13.10                                                                                   |
| Kotlin (Android)             | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)                              | 16.11                                                                                    |
| Kotlin (General)<sup>1</sup> | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules) | 16.11                                                                                   |
| Kubernetes manifests         | [Kubesec](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)                                 | 12.6                                                                                    |
| Node.js                      | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)                          | 16.11                                                                                    |
| Objective-C (iOS)            | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)                              | 16.11                                                                                    |
| PHP                          | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 16.11                                                                                    |
| Python                       | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 13.9                                                                                    |
| React                        | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 13.10                                                                                   |
| Ruby                         | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)                               | 16.11                                                                                    |
| Ruby on Rails                | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)                               | 16.11                                                                                    |
| Scala (any build system)     | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 16.0                                                                                    |
| Scala <sup>1</sup>           | [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) with the find-sec-bugs plugin | 11.0 (SBT) & 11.9 (Gradle, Maven)                                                       |
| Swift (iOS)                  | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)                              | 16.11                                                                                    |
| TypeScript                   | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with [GitLab-managed rules](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/#sast-rules)       | 13.10                                                                                   |

<html>
  Footnotes:
  <ol>
    <li>The SpotBugs-based analyzer supports <a href="https://gradle.org/">Gradle</a>, <a href="https://maven.apache.org/">Maven</a>, and <a href="https://www.scala-sbt.org/">SBT</a>. It can also be used with variants like the <a href="https://docs.gradle.org/current/userguide/gradle_wrapper.html">Gradle wrapper</a>, <a href="https://grails.org/">Grails</a>, and the <a href="https://github.com/takari/maven-wrapper">Maven wrapper</a>. However, SpotBugs has <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/350801">limitations</a> when used against <a href="https://ant.apache.org/">Ant</a>-based projects. You should use the Semgrep-based analyzer for Ant-based Java or Scala projects.</li>
    <li> These analyzers were <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/431123">deprecated in GitLab 16.9</a> and are planned for removal in 17.0. The <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep analyzer</a> is proposed as their replacement.</li>
  </ol>
</html>

## End of supported analyzers

GitLab has reached End of Support for the below analyzers. These analyzers have been replaced by the Semgrep-based analyzer.

| Language / framework         | [Analyzer](analyzers.md) used for scanning                                                                   | Minimum supported GitLab version         | End Of Support GitLab version                                 |
|------------------------------|--------------------------------------------------------------------------------------------------------------| ---------------------------------        | ------------------------------------------------------------- |
| .NET Core                    | [Security Code Scan](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan)           | 11.0                                     | [16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/390416)  |
| .NET Framework               | [Security Code Scan](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan)           | 13.0                                     | [16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/390416)  |
| Go                           | [Gosec](https://gitlab.com/gitlab-org/security-products/analyzers/gosec)                                     | 10.7                                     | [15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/352554)  |
| Java                         | [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) with the find-sec-bugs plugin | 10.6 (Maven), 10.8 (Gradle) & 11.9 (SBT) | [15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/352554)  |
| Python                       | [bandit](https://gitlab.com/gitlab-org/security-products/analyzers/bandit)                                   | 10.3                                     | [15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/352554)  |
| React                        | [ESLint react plugin](https://gitlab.com/gitlab-org/security-products/analyzers/eslint)                      | 12.5                                     | [15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/352554)  |
| JavaScript                   | [ESLint security plugin](https://gitlab.com/gitlab-org/security-products/analyzers/eslint)                   | 11.8                                     | [15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/352554)  |
| TypeScript                   | [ESLint security plugin](https://gitlab.com/gitlab-org/security-products/analyzers/eslint)                   | 11.9, with ESLint in 13.2                                     | [15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/352554)  |
| Ruby                         | [brakeman](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman)                               | 13.9                                     | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |
| Ruby on Rails                | [brakeman](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman)                               | 13.9                                     | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |
| Node.js                      | [NodeJsScan](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan)                          | 11.1                                     | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |
| Kotlin (General)             | [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)                               | 13.11                                    | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |
| Kotlin (Android)             | [MobSF](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf)                                     | 13.5                                     | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |
| Java (Android)               | [MobSF](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf)                                     | 13.5                                     | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |
| Objective-C (iOS)            | [MobSF](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf)                                     | 13.5                                     | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |
| PHP                          | [phpcs-security-audit](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit)       | 10.8                                     | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |
| C++                          | [Flawfinder](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder)                           | 10.7                                     | [17.0](https://gitlab.com/groups/gitlab-org/-/epics/13050)  |

## Multi-project support

GitLab SAST can scan repositories that contain multiple projects.

The following analyzers have multi-project support:

- Bandit
- ESLint
- Gosec
- Kubesec
- NodeJsScan
- MobSF
- PMD
- Security Code Scan
- Semgrep
- SpotBugs
- Sobelow

### Enable multi-project support for Security Code Scan

Multi-project support in the Security Code Scan requires a Solution (`.sln`) file in the root of
the repository. For details on the Solution format, see the Microsoft reference [Solution (`.sln`) file](https://learn.microsoft.com/en-us/visualstudio/extensibility/internals/solution-dot-sln-file?view=vs-2019).

## False positive detection

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378622) for Go in GitLab 15.8.

GitLab SAST can identify certain types of false positive results in the output of other tools.
These results are flagged as false positives on the [Vulnerability Report](../vulnerability_report/index.md) and the [Vulnerability Page](../vulnerabilities/index.md).

False positive detection is available in a subset of the [supported languages](#supported-languages-and-frameworks) and [analyzers](analyzers.md):

- Go, in the Semgrep-based analyzer
- Ruby, in the Brakeman-based analyzer

![SAST false-positives show in Vulnerability Pages](img/sast_vulnerability_page_fp_detection_v15_2.png)

## Advanced vulnerability tracking

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Source code is volatile; as developers make changes, source code may move within files or between files.
Security analyzers may have already reported vulnerabilities that are being tracked in the [Vulnerability Report](../vulnerability_report/index.md).
These vulnerabilities are linked to specific problematic code fragments so that they can be found and fixed.
If the code fragments are not tracked reliably as they move, vulnerability management is harder because the same vulnerability could be reported again.

GitLab SAST uses an advanced vulnerability tracking algorithm to more accurately identify when the same vulnerability has moved within a file due to refactoring or unrelated changes.

Advanced vulnerability tracking is available in a subset of the [supported languages](#supported-languages-and-frameworks) and [analyzers](analyzers.md):

- C, in the Semgrep-based only
- C++, in the Semgrep-based only
- C#, in the Semgrep-based analyzer only
- Go, in the Semgrep-based analyzer only
- Java, in the Semgrep-based analyzer only
- JavaScript, in the Semgrep-based analyzer only
- PHP, in the Semgrep-based analyzer only
- Python, in the Semgrep-based analyzer only
- Ruby, in the Semgrep-based analyzer only

Support for more languages and analyzers is tracked in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/5144).

For more information, see the confidential project `https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`. The content of this project is available only to GitLab team members.

## Automatic vulnerability resolution

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368284) in GitLab 15.9 [with a project-level flag](../../../administration/feature_flags.md) named `sec_mark_dropped_findings_as_resolved`.
> - Enabled by default in GitLab 15.10. On GitLab.com, [contact Support](https://about.gitlab.com/support/) if you need to disable the flag for your project.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/375128) in GitLab 16.2.

To help you focus on the vulnerabilities that are still relevant, GitLab SAST automatically [resolves](../vulnerabilities/index.md#vulnerability-status-values) vulnerabilities when:

- You [disable a predefined rule](customize_rulesets.md#disable-predefined-rules).
- We remove a rule from the default ruleset.

Automatic resolution is available only for findings from the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).
The Vulnerability Management system leaves a comment on automatically-resolved vulnerabilities so you still have a historical record of the vulnerability.

If you re-enable the rule later, the findings are reopened for triage.

## Supported distributions

The default scanner images are built on a base Alpine image for size and maintainability.

### FIPS-enabled images

GitLab offers an image version, based on the [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) base image,
that uses a FIPS 140-validated cryptographic module. To use the FIPS-enabled image, you can either:

- Set the `SAST_IMAGE_SUFFIX` to `-fips`.
- Add the `-fips` extension to the default image name.

For example:

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/SAST.gitlab-ci.yml
```

A FIPS-compliant image is only available for the Semgrep-based analyzer.

WARNING:
To use SAST in a FIPS-compliant manner, you must [exclude other analyzers from running](analyzers.md#customize-analyzers). If you use a FIPS-enabled image to run Semgrep in [a runner with non-root user](https://docs.gitlab.com/runner/install/kubernetes.html#running-with-non-root-user), you must update the `run_as_user` attribute under `runners.kubernetes.pod_security_context` to use the ID of `gitlab` user [created by the image](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/a5d822401014f400b24450c92df93467d5bbc6fd/Dockerfile.fips#L58), which is `1000`.

## Summary of features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Capability                                                        | In Free & Premium   | In Ultimate        |
|:---------------------------------------------------------------- -|:--------------------|:-------------------|
| Automatically scan code with [appropriate analyzers](#supported-languages-and-frameworks) | **{check-circle}**  | **{check-circle}** |
| [Configure SAST scanners](#configuration)                         | **{check-circle}**  | **{check-circle}** |
| [Customize SAST settings](#available-cicd-variables)              | **{check-circle}**  | **{check-circle}** |
| Download [SAST output](#output)                                   | **{check-circle}**  | **{check-circle}** |
| See new findings in merge request widget                          | **{dotted-circle}** | **{check-circle}** |
| See new findings in merge request changes                         | **{dotted-circle}** | **{check-circle}** |
| [Manage vulnerabilities](../vulnerabilities/index.md)             | **{dotted-circle}** | **{check-circle}** |
| [Access the Security Dashboard](../security_dashboard/index.md)   | **{dotted-circle}** | **{check-circle}** |
| [Configure SAST by using the UI](#configure-sast-by-using-the-ui) | **{dotted-circle}** | **{check-circle}** |
| [Customize SAST rulesets](customize_rulesets.md)                  | **{dotted-circle}** | **{check-circle}** |
| [Detect False Positives](#false-positive-detection)               | **{dotted-circle}** | **{check-circle}** |
| [Track moved vulnerabilities](#advanced-vulnerability-tracking)   | **{dotted-circle}** | **{check-circle}** |

## Output

SAST outputs the file `gl-sast-report.json` as a job artifact. The file contains details of all
detected vulnerabilities. You can
[download](../../../ci/jobs/job_artifacts.md#download-job-artifacts) the file for processing
outside GitLab.

For more information, see:

- [SAST report file schema](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json)
- [Example SAST report file](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/qa/expect/js/default/gl-sast-report.json)

## View SAST results

The [SAST report file](#output) is processed by GitLab and the details are shown in the UI:

- Merge request widget
- Merge request changes view
- Vulnerability report

### Merge request widget

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

SAST results display in the merge request widget area if a report from the target
branch is available for comparison. The merge request widget displays SAST results and resolutions that
were introduced by the changes made in the merge request.

![Security Merge request widget](img/sast_mr_widget_v16_7.png)

### Merge request changes view

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10959) in GitLab 16.6 with a [flag](../../../administration/feature_flags.md) named `sast_reports_in_inline_diff`. Disabled by default.
> - Enabled by default in GitLab 16.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/410191) in GitLab 16.9.

SAST results display in the merge request **Changes** view. Lines containing SAST
issues are marked by a symbol beside the gutter. Select the symbol to see the list of issues, then select an issue to see its details.

![SAST Inline Indicator](img/sast_inline_indicator_v16_7.png)

## Contribute your scanner

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate other security scanners into GitLab.

## Configuration

SAST scanning runs in your CI/CD pipeline.
When you add the GitLab-managed CI/CD template to your pipeline, the right [SAST analyzers](analyzers.md) automatically scan your code and save results as [SAST report artifacts](../../../ci/yaml/artifacts_reports.md#artifactsreportssast).

To configure SAST for a project you can:

- Use [Auto SAST](../../../topics/autodevops/stages.md#auto-sast), provided by
  [Auto DevOps](../../../topics/autodevops/index.md).
- [Configure SAST in your CI/CD YAML](#configure-sast-in-your-cicd-yaml).
- [Configure SAST by using the UI](#configure-sast-by-using-the-ui).

You can enable SAST across many projects by [enforcing scan execution](../index.md#enforce-scan-execution).

### Configure SAST in your CI/CD YAML

To enable SAST, you [include](../../../ci/yaml/index.md#includetemplate)
the [`SAST.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml).
The template is provided as a part of your GitLab installation.

Copy and paste the following to the bottom of the `.gitlab-ci.yml` file. If an `include` line
already exists, add only the `template` line below it.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

The included template creates SAST jobs in your CI/CD pipeline and scans
your project's source code for possible vulnerabilities.

The results are saved as a
[SAST report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)
that you can later download and analyze.
When downloading, you always receive the most recent SAST artifact available.

### Configure SAST by using the UI

You can enable and configure SAST by using the UI, either with the default settings or with customizations.
The method you can use depends on your GitLab license tier.

#### Configure SAST with customizations

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/410013) individual SAST analyzers configuration options from the UI in GitLab 16.2.

NOTE:
The configuration tool works best with no existing `.gitlab-ci.yml` file, or with a minimal
configuration file. If you have a complex GitLab configuration file it may not be parsed
successfully, and an error may occur.

To enable and configure SAST with customizations:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. If the project does not have a `.gitlab-ci.yml` file, select **Enable SAST** in the Static
   Application Security Testing (SAST) row, otherwise select **Configure SAST**.
1. Enter the custom SAST values.

   Custom values are stored in the `.gitlab-ci.yml` file. For CI/CD variables not in the SAST
   Configuration page, their values are inherited from the GitLab SAST template.
1. Select **Create Merge Request**.
1. Review and merge the merge request.

Pipelines now include a SAST job.

#### Configure SAST with default settings only

NOTE:
The configuration tool works best with no existing `.gitlab-ci.yml` file, or with a minimal
configuration file. If you have a complex GitLab configuration file it may not be parsed
successfully, and an error may occur.

To enable and configure SAST with default settings:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the SAST section, select **Configure with a merge request**.
1. Review and merge the merge request to enable SAST.

Pipelines now include a SAST job.

### Overriding SAST jobs

To override a job definition, (for example, change properties like `variables`, `dependencies`, or [`rules`](../../../ci/yaml/index.md#rules)),
declare a job with the same name as the SAST job to override. Place this new job after the template
inclusion and specify any additional keys under it. For example, this enables `FAIL_NEVER` for the
`spotbugs` analyzer:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

spotbugs-sast:
  variables:
    FAIL_NEVER: 1
```

### Pinning to minor image version

The GitLab-managed CI/CD template specifies a major version and automatically pulls the latest analyzer release within that major version.

In some cases, you may need to use a specific version.
For example, you might need to avoid a regression in a later release.

To override the automatic update behavior, set the `SAST_ANALYZER_IMAGE_TAG` CI/CD variable
in your CI/CD configuration file after you include the [`SAST.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml).

Only set this variable within a specific job.
If you set it [at the top level](../../../ci/variables/index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file), the version you set is used for other SAST analyzers.

You can set the tag to:

- A major version, like `3`. Your pipelines use any minor or patch updates that are released within this major version.
- A minor version, like `3.7`. Your pipelines use any patch updates that are released within this minor version.
- A patch version, like `3.7.0`. Your pipelines don't receive any updates.

This example uses a specific minor version of the `semgrep` analyzer and a specific patch version of the `brakeman` analyzer:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

semgrep-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.7"

brakeman-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.1.1"
```

### Using CI/CD variables to pass credentials for private repositories

Some analyzers require downloading the project's dependencies to
perform the analysis. In turn, such dependencies may live in private Git
repositories and thus require credentials like username and password to download them.
Depending on the analyzer, such credentials can be provided to
it via [custom CI/CD variables](#custom-cicd-variables).

#### Using a CI/CD variable to pass username and password to a private Go repository

If your Go project depends on private modules, see
[Fetch modules from private projects](../../packages/go_proxy/index.md#fetch-modules-from-private-projects)
for how to provide authentication over HTTPS.

To specify credentials via `~/.netrc` provide a `before_script` containing the following:

```yaml
gosec-sast:
  before_script:
    - |
      cat <<EOF > ~/.netrc
      machine gitlab.com
      login $CI_DEPLOY_USER
      password $CI_DEPLOY_PASSWORD
      EOF
```

#### Using a CI/CD variable to pass username and password to a private Maven repository

If your private Maven repository requires login credentials,
you can use the `MAVEN_CLI_OPTS` CI/CD variable.

Read more on [how to use private Maven repositories](../index.md#using-private-maven-repositories).

### Enabling Kubesec analyzer

You need to set `SCAN_KUBERNETES_MANIFESTS` to `"true"` to enable the
Kubesec analyzer. In `.gitlab-ci.yml`, define:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SCAN_KUBERNETES_MANIFESTS: "true"
```

### Pre-compilation

Most GitLab SAST analyzers directly scan your source code without compiling it first.
However, for technical reasons, some analyzers can only scan compiled code.

By default, these analyzers automatically attempt to fetch dependencies and compile your code so it can be scanned.
Automatic compilation can fail if:

- your project requires custom build configurations.
- you use language versions that aren't built into the analyzer.

To resolve these issues, you can skip the analyzer's compilation step and directly provide artifacts from an earlier stage in your pipeline instead.
This strategy is called _pre-compilation_.

Pre-compilation is available for the analyzers that support the `COMPILE` CI/CD variable.
See [Analyzer settings](#analyzer-settings) for the current list.

To use pre-compilation:

1. Output your project's dependencies to a directory in the project's working directory, then save that directory as an artifact by [setting the `artifacts: paths` configuration](../../../ci/yaml/index.md#artifactspaths).
1. Provide the `COMPILE: "false"` CI/CD variable to the analyzer to disable automatic compilation.
1. Add your compilation stage as a dependency for the analyzer job.

To allow the analyzer to recognize the compiled artifacts, you must explicitly specify the path to
the vendored directory.
This configuration can vary per analyzer. For Maven projects, you can use `MAVEN_REPO_PATH`.
See [Analyzer settings](#analyzer-settings) for the complete list of available options.

The following example pre-compiles a Maven project and provides it to the SpotBugs SAST analyzer:

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/SAST.gitlab-ci.yml

build:
  image: maven:3.6-jdk-8-slim
  stage: build
  script:
    - mvn package -Dmaven.repo.local=./.m2/repository
  artifacts:
    paths:
      - .m2/
      - target/

spotbugs-sast:
  dependencies:
    - build
  variables:
    MAVEN_REPO_PATH: $CI_PROJECT_DIR/.m2/repository
    COMPILE: "false"
  artifacts:
    reports:
      sast: gl-sast-report.json
```

### Running jobs in merge request pipelines

See [Use security scanning tools with merge request pipelines](../index.md#use-security-scanning-tools-with-merge-request-pipelines).

### Available CI/CD variables

SAST can be configured using the [`variables`](../../../ci/yaml/index.md#variables) parameter in
`.gitlab-ci.yml`.

WARNING:
All customization of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

The following example includes the SAST template to override the `SEARCH_MAX_DEPTH`
variable to `10`. The template is [evaluated before](../../../ci/yaml/index.md#include) the pipeline
configuration, so the last mention of the variable takes precedence.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SEARCH_MAX_DEPTH: 10
```

#### Custom Certificate Authority

To trust a custom Certificate Authority, set the `ADDITIONAL_CA_CERT_BUNDLE` variable to the bundle
of CA certs that you want to trust in the SAST environment. The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the [text representation of the X.509 PEM public-key certificate](https://www.rfc-editor.org/rfc/rfc7468#section-5.1). For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a [custom variable in the UI](../../../ci/variables/index.md#for-a-project), either as a `file`, which requires the path to the certificate, or as a variable, which requires the text representation of the certificate.

#### Docker images

The following are Docker image-related CI/CD variables.

| CI/CD variable            | Description                                                                                                                           |
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `SECURE_ANALYZERS_PREFIX` | Override the name of the Docker registry providing the default images (proxy). Read more about [customizing analyzers](analyzers.md). |
| `SAST_EXCLUDED_ANALYZERS` | Names of default images that should never run. Read more about [customizing analyzers](analyzers.md).                                 |
| `SAST_ANALYZER_IMAGE_TAG` | Override the default version of analyzer image. Read more about [pinning the analyzer image version](#pinning-to-minor-image-version).                                 |
| `SAST_IMAGE_SUFFIX`       | Suffix added to the image name. If set to `-fips`, `FIPS-enabled` images are used for scan. See [FIPS-enabled images](#fips-enabled-images) for more details. |

#### Vulnerability filters

Some analyzers make it possible to filter out vulnerabilities under a given threshold.

| CI/CD variable               | Default value            | Description                                                                                                                                                                                                                 |
|------------------------------|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SAST_EXCLUDED_PATHS`        | `spec, test, tests, tmp` | Exclude vulnerabilities from output based on the paths. This is a comma-separated list of patterns. Patterns can be globs (see [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) for supported patterns), or file or folder paths (for example, `doc,spec`). Parent directories also match patterns. You might need to exclude temporary directories used by your build tool as these can generate false positives. To exclude paths, copy and paste the default excluded paths, then **add** your own paths to be excluded. If you don't specify the default excluded paths, you override the defaults and _only_ paths you specify are excluded from the SAST scans. |
| `SEARCH_MAX_DEPTH`           | [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) 20; all other SAST analyzers 4                        | SAST searches the repository to detect the programming languages used, and selects the matching analyzers. Set the value of `SEARCH_MAX_DEPTH` to specify how many directory levels the search phase should span. After the analyzers have been selected, the _entire_ repository is analyzed. |
| `SAST_BANDIT_EXCLUDED_PATHS` |                          | Comma-separated list of paths to exclude from scan. Uses Python's [`fnmatch` syntax](https://docs.python.org/2/library/fnmatch.html); For example: `'*/tests/*, */venv/*'`. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4. |
| `SAST_BRAKEMAN_LEVEL`        | 1                        | Ignore Brakeman vulnerabilities under given confidence level. Integer, 1=Low 3=High.                                                                                                                                        |
| `SAST_FLAWFINDER_LEVEL`      | 1                        | Ignore Flawfinder vulnerabilities under given risk level. Integer, 0=No risk, 5=High risk.                                                                                                                                  |
| `SAST_GOSEC_LEVEL`           | 0                        | Ignore Gosec vulnerabilities under given confidence level. Integer, 0=Undefined, 1=Low, 2=Medium, 3=High. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4. |

#### Analyzer settings

Some analyzers can be customized with CI/CD variables.

| CI/CD variable              | Analyzer   | Description                                                                                                                                                                                                                        |
|-----------------------------|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SCAN_KUBERNETES_MANIFESTS` | Kubesec    | Set to `"true"` to scan Kubernetes manifests.                                                                                                                                                                                      |
| `KUBESEC_HELM_CHARTS_PATH`  | Kubesec    | Optional path to Helm charts that `helm` uses to generate a Kubernetes manifest that `kubesec` scans. If dependencies are defined, `helm dependency build` should be ran in a `before_script` to fetch the necessary dependencies. |
| `KUBESEC_HELM_OPTIONS`      | Kubesec    | Additional arguments for the `helm` executable.                                                                                                                                                                                    |
| `COMPILE`                   | Gosec, SpotBugs   | Set to `false` to disable project compilation and dependency fetching.                                                                                                                                                                                                        |
| `ANT_HOME`                  | SpotBugs   | The `ANT_HOME` variable.                                                                                                                                                                                                        |
| `ANT_PATH`                  | SpotBugs   | Path to the `ant` executable.                                                                                                                                                                                                     |
| `GRADLE_PATH`               | SpotBugs   | Path to the `gradle` executable.                                                                                                                                                                                                   |
| `JAVA_OPTS`                 | SpotBugs   | Additional arguments for the `java` executable.                                                                                                                                                                                    |
| `JAVA_PATH`                 | SpotBugs   | Path to the `java` executable.                                                                                                                                                                                                     |
| `SAST_JAVA_VERSION`         | SpotBugs   | Which Java version to use. [Starting in GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/352549), supported versions are `11` and `17` (default). Before GitLab 15.0, supported versions are `8` (default) and `11`.     |
| `MAVEN_CLI_OPTS`            | SpotBugs   | Additional arguments for the `mvn` or `mvnw` executable.                                                                                                                                                                           |
| `MAVEN_PATH`                | SpotBugs   | Path to the `mvn` executable.                                                                                                                                                                                                      |
| `MAVEN_REPO_PATH`           | SpotBugs   | Path to the Maven local repository (shortcut for the `maven.repo.local` property).                                                                                                                                                 |
| `SBT_PATH`                  | SpotBugs   | Path to the `sbt` executable.                                                                                                                                                                                                      |
| `FAIL_NEVER`                | SpotBugs   | Set to `1` to ignore compilation failure.                                                                                                                                                                                          |

| `PHPCS_SECURITY_AUDIT_PHP_EXTENSIONS` | phpcs-security-audit | Comma separated list of additional PHP Extensions.                                                                                                                                                             |
| `SAST_SEMGREP_METRICS` | Semgrep | Set to `"false"` to disable sending anonymized scan metrics to [r2c](https://semgrep.dev). Default: `true`. |
| `SAST_SCANNER_ALLOWED_CLI_OPTS`        | Semgrep | CLI options (arguments with value, or flags) that are passed to the underlying security scanner when running scan operation. Only a limited set of [options](#security-scanner-configuration) are accepted. Separate a CLI option and its value using either a blank space or equals (`=`) character. For example: `name1 value1` or `name1=value1`. Multiple options must be separated by blank spaces. For example: `name1 value1 name2 value2`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368565) in GitLab 15.3. |
| `SAST_RULESET_GIT_REFERENCE` | Semgrep and nodejs-scan | Defines a path to a custom ruleset configuration. If a project has a `.gitlab/sast-ruleset.toml` file committed, that local configuration takes precedence and the file from `SAST_RULESET_GIT_REFERENCE` isn’t used. This variable is available for the Ultimate tier only. |

#### Security scanner configuration

SAST analyzers internally use OSS security scanners to perform the analysis. We set the recommended
configuration for the security scanner so that you need not to worry about tuning them. However,
there can be some rare cases where our default scanner configuration does not suit your
requirements.

To allow some customization of scanner behavior, you can add a limited set of flags to the
underlying scanner. Specify the flags in the `SAST_SCANNER_ALLOWED_CLI_OPTS` CI/CD variable. These
flags are added to the scanner's CLI options.

| Analyzer                                                                     | CLI option         | Description |
|------------------------------------------------------------------------------|--------------------|------------------------------------------------------------------------------|
| [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) | `--max-memory`     | Sets the maximum system memory to use when running a rule on a single file. Measured in MB. |
| [Flawfinder](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder) | `--neverignore` | Never ignore security issues, even if they have an "ignore" directive in a comment. Adding this option is likely to result in the analyzer detecting additional vulnerability findings which cannot be automatically resolved. |
| [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) | `-effort` | Sets the analysis effort level. Valid values are `min`, `less`, `more` and `max`, defined in increasing order of scan's precision and ability to detect more vulnerabilities. Default value is set to `max` which may require more memory and time to complete the scan, depending on the project's size. In case you face memory or performance issues, you may reduce the analysis effort level to a lower value. For example: `-effort less`. |

#### Custom CI/CD variables

In addition to the aforementioned SAST configuration CI/CD variables,
all [custom variables](../../../ci/variables/index.md#define-a-cicd-variable-in-the-ui) are propagated
to the underlying SAST analyzer images if
[the SAST vendored template](#configuration) is used.

### Experimental features

You can receive early access to experimental features. Experimental features might be added,
removed, or promoted to regular features at any time.

Experimental features available are:

- Enable scanning of iOS and Android apps using the [MobSF analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf/). This includes the automatic detection and scanning of Xcode projects, Android manifest files, `.ipa` (iOS) and `.apk` (Android) binary files.

These features were previously experimental, but are now generally available:

- Disable the [`eslint.detect-object-injection`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/6c4764567d9854f5e4a4a35dacf5a68def7fb4c1/rules/eslint.yml#L751-773) in the [Semgrep analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) because it causes a high rate of false positives.
  - This rule was [disabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/373920) in 15.10.

#### Enable experimental features

To enable experimental features, add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_EXPERIMENTAL_FEATURES: "true"
```

## Running SAST in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for the SAST job to
run successfully. For more information, see [Offline environments](../offline_deployments/index.md).

### Requirements for offline SAST

To use SAST in an offline environment, you need:

- GitLab Runner with the [`docker` or `kubernetes` executor](#requirements).
- A Docker container registry with locally available copies of SAST [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers) images.
- Configure certificate checking of packages (optional).

GitLab Runner has a [default `pull_policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. The GitLab Runner [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

### Make GitLab SAST analyzer images available inside your Docker registry

For SAST with all [supported languages and frameworks](#supported-languages-and-frameworks),
import the following default SAST analyzer images from `registry.gitlab.com` into your
[local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/security-products/kubesec:5
registry.gitlab.com/security-products/pmd-apex:5
registry.gitlab.com/security-products/semgrep:5
registry.gitlab.com/security-products/sobelow:5
registry.gitlab.com/security-products/spotbugs:5
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed. These scanners are [periodically updated](../index.md#vulnerability-scanner-maintenance)
with new definitions, and you may be able to make occasional updates on your own.

For details on saving and transporting Docker images as a file, see the Docker documentation on
[`docker save`](https://docs.docker.com/reference/cli/docker/image/save/), [`docker load`](https://docs.docker.com/reference/cli/docker/image/load/),
[`docker export`](https://docs.docker.com/reference/cli/docker/container/export/), and [`docker import`](https://docs.docker.com/reference/cli/docker/image/import/).

#### If support for Custom Certificate Authorities are needed

Support for custom certificate authorities was introduced in the following versions.

| Analyzer               | Version                                                                                                    |
| --------               | -------                                                                                                    |
| `bandit`<sup>1</sup>   | [v2.3.0](https://gitlab.com/gitlab-org/security-products/analyzers/bandit/-/releases/v2.3.0)               |
| `brakeman`             | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman/-/releases/v2.1.0)             |
| `eslint`<sup>1</sup>   | [v2.9.2](https://gitlab.com/gitlab-org/security-products/analyzers/eslint/-/releases/v2.9.2)               |
| `flawfinder`           | [v2.3.0](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder/-/releases/v2.3.0)           |
| `gosec`<sup>1</sup>    | [v2.5.0](https://gitlab.com/gitlab-org/security-products/analyzers/gosec/-/releases/v2.5.0)                |
| `kubesec`              | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec/-/releases/v2.1.0)              |
| `nodejs-scan`          | [v2.9.5](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan/-/releases/v2.9.5)          |
| `phpcs-security-audit` | [v2.8.2](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit/-/releases/v2.8.2) |
| `pmd-apex`             | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/releases/v2.1.0)             |
| `security-code-scan`   | [v2.7.3](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan/-/releases/v2.7.3)   |
| `semgrep`              | [v0.0.1](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/releases/v0.0.1)              |
| `sobelow`              | [v2.2.0](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/releases/v2.2.0)              |
| `spotbugs`             | [v2.7.1](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/releases/v2.7.1)             |

1. These analyzers [reached End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4.

### Set SAST CI/CD variables to use local SAST analyzers

Add the following configuration to your `.gitlab-ci.yml` file. You must replace
`SECURE_ANALYZERS_PREFIX` to refer to your local Docker container registry:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
```

The SAST job should now use local copies of the SAST analyzers to scan your code and generate
security reports without requiring internet access.

### Configure certificate checking of packages

If a SAST job invokes a package manager, you must configure its certificate verification. In an
offline environment, certificate verification with an external source is not possible. Either use a
self-signed certificate or disable certificate verification. Refer to the package manager's
documentation for instructions.

## Running SAST in SELinux

By default SAST analyzers are supported in GitLab instances hosted on SELinux. Adding a `before_script` in an [overridden SAST job](#overriding-sast-jobs) may not work as runners hosted on SELinux have restricted permissions.
