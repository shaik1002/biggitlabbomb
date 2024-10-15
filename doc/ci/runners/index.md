---
stage: Verify
group: Hosted Runners
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab-hosted runners

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

You can run your CI/CD jobs on GitLab.com and GitLab Dedicated using GitLab-hosted runners to seamlessly build, test and deploy
your application on different environments.

## Hosted runners for GitLab.com

These runners fully integrated with GitLab.com and are enabled by default for all projects, with no configuration required.
Your jobs can run on:

- [Hosted runners on Linux](hosted_runners/linux.md)
- [GPU-enabled hosted runners](hosted_runners/gpu_enabled.md)
- [Hosted runners on Windows](hosted_runners/windows.md) ([Beta](../../policy/experiment-beta-support.md#beta))
- [Hosted runners on macOS](hosted_runners/macos.md) ([Beta](../../policy/experiment-beta-support.md#beta))

### How hosted runners for GitLab.com work

When you use hosted runners:

- Each of your jobs runs in a newly provisioned VM, which is dedicated to the specific job.
- The virtual machine where your job runs has `sudo` access with no password.
- The storage is shared by the operating system, the image with pre-installed software, and a copy of your cloned repository.
  This means that the available free disk space for your jobs to use is reduced.
- [Untagged](../yaml/index.md#tags) jobs run on the `small` Linux x86-64 runner.

NOTE:
Jobs handled by hosted runners on GitLab.com **time out after 3 hours**, regardless of the timeout configured in a project.

### Security of hosted runners for GitLab.com

The following section provides an overview of the additional built-in layers that harden the security of the GitLab Runner build environment.

Hosted runners for GitLab.com are configured as such:

- Firewall rules only allow outbound communication from the ephemeral VM to the public internet.
- Inbound communication from the public internet to the ephemeral VM is not allowed.
- Firewall rules do not permit communication between VMs.
- The only internal communication allowed to the ephemeral VMs is from the runner manager.
- VM isolation between job executions.
- Ephemeral runner VMs will only serve a single job and will be deleted right after the job execution.

#### Architecture diagram of hosted runners for GitLab.com

The following graphic shows the architecture diagram of hosted runners for GitLab.com

![Hosted runners for GitLab.com architecture](img/gitlab-hosted_runners_architecture.png)

For more information on how runners are authenticating and executing the job payload, see [Runner Execution Flow](https://docs.gitlab.com/runner#runner-execution-flow).

#### Job isolation of hosted runners for GitLab.com

In addition to isolating runners on the network, each ephemeral runner VM only serves a single job and is deleted straight after the job execution.
In the following example, three jobs are executed in a project's pipeline. Each of these jobs runs in a dedicated ephemeral VM.

![Job isolation](img/build_isolation.png)

The build job ran on `runner-ns46nmmj-project-43717858`, test job on `f131a6a2runner-new2m-od-project-43717858` and deploy job on `runner-tmand5m-project-43717858`.

GitLab sends the command to remove the ephemeral runner VM to the Google Compute API immediately after the CI job completes. The [Google Compute Engine hypervisor](https://cloud.google.com/blog/products/gcp/7-ways-we-harden-our-kvm-hypervisor-at-google-cloud-security-in-plaintext)
takes over the task of securely deleting the virtual machine and associated data.

For more information about the security of hosted runners for GitLab.com, see
[Google Cloud Infrastructure Security Design Overview whitepaper](https://cloud.google.com/docs/security/infrastructure/design/resources/google_infrastructure_whitepaper_fa.pdf),
[GitLab Trust Center](https://about.gitlab.com/security/), or [GitLab Security Compliance Controls](https://handbook.gitlab.com/handbook/security/security-assurance/security-compliance/sec-controls/).

### Caching on hosted runners for GitLab.com

The hosted runners share a [distributed cache](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)
stored in a Google Cloud Storage (GCS) bucket. Cache contents not updated in the last 14 days are automatically
removed, based on the [object lifecycle management policy](https://cloud.google.com/storage/docs/lifecycle).
The maximum size of an uploaded cache artifact can be 5 GB after the cache becomes a compressed archive.

For more information about how caching works, see [Architecture diagram of hosted runners for GitLab.com](#architecture-diagram-of-hosted-runners-for-gitlabcom), and [Caching in GitLab CI/CD](../caching/index.md).

### Pricing of hosted runners for GitLab.com

Jobs that run on hosted runners for GitLab.com consume [compute minutes](../pipelines/cicd_minutes.md) allocated to your namespace.
The number of minutes you can use on these runners depends on the included compute minutes in your [subscription plan](https://about.gitlab.com/pricing/) or [additionally purchased compute minutes](../pipelines/cicd_minutes.md#purchase-additional-compute-minutes).

For more information about the cost factor applied to the machine type based on size, see [cost factor](../../ci/pipelines/cicd_minutes.md#gitlab-hosted-runner-costs).

### SLO & Release cycle for hosted runners for GitLab.com

Our SLO objective is to make 90% of CI/CD jobs start executing in 120 seconds or less. The error rate should be less than 0.5%.

We aim to update to the latest version of [GitLab Runner](https://docs.gitlab.com/runner/#gitlab-runner-versions) within a week of its release.
You can find all GitLab Runner breaking changes under [Deprecations and removals](../../update/deprecations.md).

## Hosted runners for GitLab community contributions

If you want to [contribute to GitLab](https://about.gitlab.com/community/contribute/), jobs will be picked up by the
`gitlab-shared-runners-manager-X.gitlab.com` fleet of runners, dedicated for GitLab projects and related community forks.

These runners are backed by the same machine type as our `small` Linux x86-64 runners.
Unlike hosted runners for GitLab.com, hosted runners for GitLab community contributions are re-used up to 40 times.

As we want to encourage people to contribute, these runners are free of charge.

## Hosted runners for GitLab Dedicated

These runners are created on-demand for GitLab Dedicated customers and are fully integrated with your GitLab Dedicated instance.
Your jobs can run on:

- [Hosted runners on Linux](hosted_runners/linux.md) ([Beta](../../policy/experiment-beta-support.md#beta))

## Supported image lifecycle

Hosted runners on macOS and Windows can only run jobs on supported images. You cannot bring your own image.
Supported images have the following lifecycle:

### Beta

New images are released as Beta. This allows us to gather feedback and address potential issues before General Availablility (GA).
Any jobs running on Beta images are not covered by the service-level agreement.
If you use Beta images, you can provide feedback by creating an issue.

### General Availablility (GA)

A image becomes generally available after the image completes the Beta phase and is considered stable.
To become GA, the image must fulfill the following requirements:

- Successful completion of a Beta phase by resolving all reported significant bugs
- Compatibility of installed software with the underlying OS

Jobs that run on GA images are covered by the defined service-level agreement.

### Deprecated

A maximum of two Generally Available (GA) images are supported at a time. After a new GA image is released,
the oldest GA image becomes deprecated. A deprecated image is no longer updated and is deleted after 3 months
in accordance with the [deprecation guidelines](../../development/deprecation_guidelines/index.md).
