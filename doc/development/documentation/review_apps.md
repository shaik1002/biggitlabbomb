---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how documentation review apps work.
---

# Documentation review apps

GitLab team members can deploy a [review app](../../ci/review_apps/index.md) for merge requests with documentation
changes. The review app helps you preview what the changes would look like if they were deployed to either:

- The [GitLab Docs site](https://docs.gitlab.com).
- The [new GitLab Docs site](https://new.docs.gitlab.com). The site is still in development.

Review apps deployments are available for these projects:

- [GitLab](https://gitlab.com/gitlab-org/gitlab)
- [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab)
- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)
- [GitLab Charts](https://gitlab.com/gitlab-org/charts/gitlab)
- [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator)

## Deploy a review app and preview changes

Prerequisites:

- You must have the Developer role for the project. External contributors cannot run these jobs and
should ask a GitLab team member to run the jobs for them.

Merge requests with documentation changes have the following jobs available:

- `review-docs-deploy`, which uses Nanoc static-site generation using
  [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs).
- `review-docs-hugo-deploy`: Optional. This review app is only for testing the Hugo static site generation from
  [`gitlab-docs-hugo`](https://gitlab.com/gitlab-org/technical-writing-group/gitlab-docs-hugo),
  which is still in development.

To deploy a review app and preview changes:

1. [Manually run](../../ci/jobs/job_control.md#run-a-manual-job) either (or both) of these jobs. These jobs trigger a
   [multi project pipelines](../../ci/pipelines/downstream_pipelines.md#multi-project-pipelines), build the
   documentation site with your changes, and deploy a site with your changes.
1. When the pipeline finishes, select **View app** on either deployment to open a browser and review the
   changes introduced by the merge request.

The `review-docs-cleanup` and `review-docs-hugo-cleanup` jobs are triggered automatically on merge. These job delete
the review app.

## How documentation review apps work

Documentation review apps follow this process:

1. You manually run the `review-docs-deploy` or `review-docs-hugo-deploy` job in a merge request.
1. The job downloads (if outside of `gitlab` project) and runs the
   [`scripts/trigger-build.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/trigger-build.rb) script with
   either:

   - The `docs deploy` flag, which triggers a pipeline in the `gitlab-org/gitlab-docs` project.
   - The `docs-hugo deploy` flag, which triggers a pipeline in the `gitlab-org/technical-writing-group/gitlab-docs-hugo`
     project.

   The `DOCS_BRANCH` environment variable determines which branch of either the `gitlab-org/gitlab-docs` project or the
   `gitlab-org/technical-writing-group/gitlab-docs-hugo` project are used. If not set, the `main` branch is used.
1. After the documentation preview site is built:
   - For `nanoc` builds, the HTML files are uploaded as [artifacts](../../ci/yaml/index.md#artifacts) to a GCP bucket.
     For implementation details, see
     [issue `gitlab-com/gl-infra/reliability#11021`](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11021).
   - For `hugo` builds, a [parallel deployment](../../user/project/pages/index.md#parallel-deployments) is deployed.
