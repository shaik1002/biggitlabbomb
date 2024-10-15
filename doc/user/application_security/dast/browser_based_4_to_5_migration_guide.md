---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrating from the DAST version 4 browser-based analyzer to DAST version 5

> - The [DAST proxy-based analyzer](proxy-based.md) was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) in GitLab 16.6 and removed in 17.0.

[DAST version 5](browser/index.md) replaces DAST version 4. This document serves as a guide to
migrate from the DAST version 4 browser-based analyzer to DAST version 5.

Follow this migration guide if all the following conditions apply:

1. You use GitLab DAST to run a DAST scan in a CI/CD pipeline.
1. The DAST CI/CD job is configured by including either of the DAST templates `DAST.gitlab-ci.yml` or `DAST.latest.gitlab-ci.yml`.
1. The CI/CD variable `DAST_VERSION` is not set or is set to `4` or less.
1. The CI/CD variable `DAST_BROWSER_SCAN` is set to `true`.

Migrate to DAST version 5 by reading the following sections and making the recommended changes.

## DAST analyzer versions

DAST comes in two major versions: 4 and 5. Effective from the third GitLab 17.0 breaking change window,
2024-05-06 09:00 UTC to 2024-05-08 22:00 UTC, the DAST templates `DAST.gitlab-ci.yml` and `DAST.latest.gitlab-ci.yml`
use DAST version 5 by default. You can continue using DAST version 4, but you should do so only as an
interim measure while migrating to DAST version 5. For details, see [Continuing to use version 4](#continuing-to-use-version-4).

Each DAST major version runs different analyzers:

- DAST version 4 can run either the proxy-based or browser-based analyzer, and uses the proxy-based analyzer by default.
- DAST version 5 runs only the browser-based analyzer.

DAST version 5 uses a set of new CI/CD variables. Aliases have been created for the DAST version 4 variables' names.

Changes to make:

- To test your DAST scan using DAST version 5 in GitLab 16.11 and earlier, set the CI/CD variable `DAST_VERSION` to 5.

## Continuing to use version 4

You can use the DAST version 4 browser-based analyzer until GitLab 18.0. Bugs and vulnerabilities in this legacy analyzer will not be fixed.

Changes to make:

- To continue using DAST version 4, set the CI/CD variable `DAST_VERSION` variable to 4.

## Artifacts

GitLab 17.0 automatically publishes artifacts produced by DAST version 5 to the DAST CI job.

Changes to make:

- Remove `artifacts` from the CI job definition if you have overridden it to expose the file log, crawl graph, or authentication report.
- CI/CD variables `DAST_BROWSER_FILE_LOG_PATH` and `DAST_FILE_LOG_PATH` are no longer required.

## Vulnerability check coverage

Browser-based DAST version 4 uses proxy-based analyzer checks for active checks not included in the browser-based analyzer.
Browser-based DAST version 5 does not include the proxy-based analyzer, so there is a gap in check coverage when migrating to version 5.

There are three proxy-based active checks that the browser-based analyzer does not cover. Adding more checks to provide complete coverage
is in active development, you may remain on DAST version 4 until they are complete. See [Continuing to use version 4](#continuing-to-use-version-4).

Remaining checks:

- CWE-79: Cross-site Scripting (XSS)
- CWE-384: Session Fixation
- CWE-16: TRACE HTTP

Follow the progress of the remaining checks in the epic [Remaining active checks for BBD](https://gitlab.com/groups/gitlab-org/-/epics/13411).

## Changes to CI/CD variables

The following table outlines migration actions required for each browser-based analyzer DAST version 4 CI/CD variable.
See [configuration](browser/configuration) for more information on configuring the browser-based analyzer.

| DAST version 4 CI/CD variable               | Required action    | Notes                                         |
|:--------------------------------------------|:-------------------|:----------------------------------------------|
| `DAST_ADVERTISE_SCAN`                       | Rename             | To `DAST_REQUEST_ADVERTISE_SCAN`              |
| `DAST_AUTH_COOKIES`                         | Rename             | To `DAST_AUTH_COOKIE_NAMES`                   |
| `DAST_AUTH_DISABLE_CLEAR_FIELDS`            | Rename             | To `DAST_AUTH_CLEAR_INPUT_FIELDS`             |
| `DAST_AUTH_REPORT`                          | No action required |                                               |
| `DAST_AUTH_TYPE`                            | No action required |                                               |
| `DAST_AUTH_URL`                             | No action required |                                               |
| `DAST_AUTH_VERIFICATION_LOGIN_FORM`         | Rename             | To `DAST_AUTH_SUCCESS_IF_NO_LOGIN_FORM`       |
| `DAST_AUTH_VERIFICATION_SELECTOR`           | Rename             | To `DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND`       |
| `DAST_AUTH_VERIFICATION_URL`                | Rename             | To `DAST_AUTH_SUCCESS_IF_AT_URL`              |
| `DAST_BROWSER_PATH_TO_LOGIN_FORM`           | Rename             | To `DAST_AUTH_BEFORE_LOGIN_ACTIONS`           |
| `DAST_BROWSER_ACTION_STABILITY_TIMEOUT`     | Replace            | With `DAST_PAGE_DOM_READY_TIMEOUT`            |
| `DAST_BROWSER_ACTION_TIMEOUT`               | Remove             | Not supported                                 |
| `DAST_BROWSER_ALLOWED_HOSTS`                | Rename             | To `DAST_SCOPE_ALLOW_HOSTS`                   |
| `DAST_BROWSER_COOKIES`                      | Rename             | To `DAST_REQUEST_COOKIES`                     |
| `DAST_BROWSER_CRAWL_GRAPH`                  | Rename             | To `DAST_CRAWL_GRAPH`                         |
| `DAST_BROWSER_CRAWL_TIMEOUT`                | Rename             | To `DAST_CRAWL_TIMEOUT`                       |
| `DAST_BROWSER_DEVTOOLS_LOG`                 | Rename             | To `DAST_LOG_DEVTOOLS_CONFIG`                 |
| `DAST_BROWSER_DOM_READY_AFTER_TIMEOUT`      | Rename             | To `DAST_PAGE_DOM_STABLE_WAIT`                |
| `DAST_BROWSER_ELEMENT_TIMEOUT`              | Rename             | To `DAST_PAGE_ELEMENT_READY_TIMEOUT`          |
| `DAST_BROWSER_EXCLUDED_ELEMENTS`            | Rename             | To `DAST_SCOPE_EXCLUDE_ELEMENTS`              |
| `DAST_BROWSER_EXCLUDED_HOSTS`               | Rename             | To `DAST_SCOPE_EXCLUDE_HOSTS`                 |
| `DAST_BROWSER_EXTRACT_ELEMENT_TIMEOUT`      | Rename             | To `DAST_CRAWL_EXTRACT_ELEMENT_TIMEOUT`       |
| `DAST_BROWSER_FILE_LOG`                     | Rename             | To `DAST_LOG_FILE_CONFIG`                     |
| `DAST_BROWSER_FILE_LOG_PATH`                | Remove             | No longer required                            |
| `DAST_BROWSER_IGNORED_HOSTS`                | Rename             | To `DAST_SCOPE_IGNORE_HOSTS`                  |
| `DAST_BROWSER_INCLUDE_ONLY_RULES`           | Rename             | To `DAST_CHECKS_TO_RUN`                       |
| `DAST_BROWSER_LOG`                          | Rename             | To `DAST_LOG_CONFIG`                          |
| `DAST_BROWSER_LOG_CHROMIUM_OUTPUT`          | Rename             | To `DAST_LOG_BROWSER_OUTPUT`                  |
| `DAST_BROWSER_MAX_ACTIONS`                  | Rename             | To `DAST_CRAWL_MAX_ACTIONS`                   |
| `DAST_BROWSER_MAX_DEPTH`                    | Rename             | To `DAST_CRAWL_MAX_DEPTH`                     |
| `DAST_BROWSER_MAX_RESPONSE_SIZE_MB`         | Rename             | To `DAST_PAGE_MAX_RESPONSE_SIZE_MB`           |
| `DAST_BROWSER_NAVIGATION_STABILITY_TIMEOUT` | Rename             | To `DAST_PAGE_DOM_READY_TIMEOUT`              |
| `DAST_BROWSER_NAVIGATION_TIMEOUT`           | Rename             | To `DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT` |
| `DAST_BROWSER_NUMBER_OF_BROWSERS`           | Rename             | To `DAST_CRAWL_WORKER_COUNT`                  |
| `DAST_BROWSER_PAGE_LOADING_SELECTOR`        | Rename             | To `DAST_PAGE_IS_LOADING_ELEMENT`             |
| `DAST_BROWSER_PAGE_READY_SELECTOR`          | Rename             | To `DAST_PAGE_IS_READY_ELEMENT`               |
| `DAST_BROWSER_PASSIVE_CHECK_WORKERS`        | Rename             | To `DAST_PASSIVE_SCAN_WORKER_COUNT`           |
| `DAST_BROWSER_SCAN`                         | Remove             | No longer required                            |
| `DAST_BROWSER_SEARCH_ELEMENT_TIMEOUT`       | Rename             | To `DAST_CRAWL_SEARCH_ELEMENT_TIMEOUT`        |
| `DAST_BROWSER_STABILITY_TIMEOUT`            | Rename             | To `DAST_PAGE_READY_AFTER_ACTION_TIMEOUT`     |
| `DAST_EXCLUDE_RULES`                        | Rename             | To `DAST_CHECKS_TO_EXCLUDE`                   |
| `DAST_EXCLUDE_URLS`                         | Rename             | To `DAST_SCOPE_EXCLUDE_URLS`                  |
| `DAST_FF_ENABLE_BAS`                        | Remove             | Not supported                                 |
| `DAST_FILE_LOG_PATH`                        | Remove             | No longer required                            |
| `DAST_FIRST_SUBMIT_FIELD`                   | Rename             | To `DAST_AUTH_FIRST_SUBMIT_FIELD`             |
| `DAST_FULL_SCAN_ENABLED`                    | Rename             | To `DAST_FULL_SCAN`                           |
| `DAST_PASSWORD`                             | Rename             | To `DAST_AUTH_PASSWORD`                       |
| `DAST_PASSWORD_FIELD`                       | Rename             | To `DAST_AUTH_PASSWORD_FIELD`                 |
| `DAST_PATHS`                                | Rename             | To `DAST_TARGET_PATHS`                        |
| `DAST_PATHS_FILE`                           | Rename             | To `DAST_TARGET_PATHS_FROM_FILE`              |
| `DAST_PKCS12_CERTIFICATE_BASE64`            | No action required |                                               |
| `DAST_PKCS12_PASSWORD`                      | No action required |                                               |
| `DAST_REQUEST_HEADERS`                      | No action required |                                               |
| `DAST_SKIP_TARGET_CHECK`                    | Rename             | To `DAST_TARGET_CHECK_SKIP`                   |
| `DAST_SUBMIT_FIELD`                         | Rename             | To `DAST_AUTH_SUBMIT_FIELD`                   |
| `DAST_TARGET_AVAILABILITY_TIMEOUT`          | Rename             | To `DAST_TARGET_CHECK_TIMEOUT`                |
| `DAST_USERNAME`                             | Rename             | To `DAST_AUTH_USERNAME`                       |
| `DAST_USERNAME_FIELD`                       | Rename             | To `DAST_AUTH_USERNAME_FIELD`                 |
| `DAST_WEBSITE`                              | Rename             | To `DAST_TARGET_URL`                          |
