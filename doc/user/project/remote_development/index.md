---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Write and compile code in your browser, using a secure cloud-based environment."
---

# Remote development

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95169) in GitLab 15.4 [with a flag](../../../administration/feature_flags.md) named `vscode_web_ide`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/371084) in GitLab 15.7.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741) in GitLab 15.11.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `vscode_web_ide`. On GitLab.com and GitLab Dedicated, this feature is available. This feature is not ready for production use.

You can use remote development to write and compile code hosted on GitLab.
With remote development, you can:

- Create a secure development environment in the cloud.
- Connect to that environment from your local machine through a web browser or client-based solution.

## Web IDE as a frontend

You can use the [Web IDE](../web_ide/index.md) to make, commit, and push changes to a project directly from your web browser.
This way, you can update any project without having to install any dependencies or clone any repositories locally.

The Web IDE, however, lacks a native runtime environment where you could compile code, run tests, or generate real-time feedback.
With remote development, you can use:

- The Web IDE as a frontend
- A separate machine as a backend runtime environment

For a complete IDE experience, connect the Web IDE to a development environment configured to run as a remote host.
You can create this environment [outside](connect_machine.md) of GitLab.

## Manage a development environment

### Create a development environment

To create a development environment, run this command:

```shell
export CERTS_DIR="/home/ubuntu/.certbot/config/live/${DOMAIN}"
export PROJECTS_DIR="/home/ubuntu"

docker run -d \
  --name my-environment \
  -p 3443:3443 \
  -v "${CERTS_DIR}/fullchain.pem:/gitlab-rd-web-ide/certs/fullchain.pem" \
  -v "${CERTS_DIR}/privkey.pem:/gitlab-rd-web-ide/certs/privkey.pem" \
  -v "${PROJECTS_DIR}:/projects" \
  registry.gitlab.com/gitlab-org/remote-development/gitlab-rd-web-ide-docker:0.2-alpha \
  --log-level warn --domain "${DOMAIN}" --ignore-version-mismatch
```

The new development environment starts automatically.

### Stop a development environment

To stop a running development environment, run this command:

```shell
docker container stop my-environment
```

### Start a development environment

To start a stopped development environment, run this command:

```shell
docker container start my-environment
```

The token changes every time you start the development environment.

### Remove a development environment

To remove a development environment:

1. [Stop the development environment](#stop-a-development-environment).
1. Run this command:

   ```shell
   docker container rm my-environment
   ```
