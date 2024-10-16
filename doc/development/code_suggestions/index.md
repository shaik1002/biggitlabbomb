---
stage: Create
group: Code Creation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Code Suggestions documentation for developers interested in contributing features or bugfixes."
---

# Code Suggestions development guidelines

## Code Suggestions development setup

The recommended setup for locally developing and debugging Code Suggestions is to have all 3 different components running:

- IDE Extension (e.g. VS Code Extension).
- Main application configured correctly (e.g. GDK).
- [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist).

This should enable everyone to see locally any change in an IDE being sent to the main application transformed to a prompt which is then sent to the respective model.

### Setup instructions

1. Install and run locally the [VS Code Extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CONTRIBUTING.md#configuring-development-environment):
   1. Add the `"gitlab.debug": true` info to the Code Suggestions development config:
      1. In VS Code, go to the Extensions page and find "GitLab Workflow" in the list.
      1. Open the extension settings by clicking a small cog icon and select "Extension Settings" option.
      1. Check a "GitLab: Debug" checkbox.
   1. If you'd like to test code suggestions are working from inside the VS Code Extension, then follow the [steps to set up a personal access token](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#setup) with your GDK inside the new window of VS Code that pops up when you run the "Run and Debug" command.
      - Once you complete the steps below, to test you are hitting your local `/code_suggestions/completions` endpoint and not production, follow these steps:
        1. Inside the new window, in the built in terminal select the "Output" tab then "GitLab Language Server" from the drop down menu on the right.
        1. Open a new file inside of this VS Code window and begin typing to see code suggestions in action.
        1. You will see completion request URLs being fetched that match the Git remote URL for your GDK.

1. Main Application (GDK):
   1. Install the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/index.md#one-line-installation).
   1. Enable Feature Flag ```ai_duo_code_suggestions_switch```:
      1. In your terminal, go to your `gitlab-development-kit` > `gitlab` directory.
      1. Run `gdk rails console` or `bundle exec rails c` to start a Rails console.
      1. [Enable the Feature Flag](../../administration/feature_flags.md#enable-or-disable-the-feature) for the code suggestions tokens API by calling `Feature.enable(:ai_duo_code_suggestions_switch)` from the console.
   1. [Setup AI Gateway](../ai_features/index.md#local-setup).
   1. Run your GDK server with `gdk start` if it's not already running.

### Setup instructions to use staging AI Gateway

When testing interactions with the AI Gateway, you might want to integrate your local GDK
with the deployed staging AI Gateway. To do this:

1. You need a cloud staging license that has the Code Suggestions add-on,
   because add-ons are enabled on staging. Drop a note in the `#s_fulfillment` or `s_fulfillment_engineering` internal Slack channel to request an add-on to your license. See this [handbook page](https://handbook.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses) for how to request a license for local development.
1. Set environment variables to point customers-dot to staging, and the AI Gateway to staging:

   ```shell
   export GITLAB_LICENSE_MODE=test
   export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
   export AI_GATEWAY_URL=https://cloud.staging.gitlab.com/ai
   ```

1. Restart the GDK.
1. Ensure you followed the necessary [steps to enable the Code Suggestions feature](../../user/project/repository/code_suggestions/index.md).
1. Test out the Code Suggestions feature by opening the Web IDE for a project.

### Setup instructions to use GDK with the Code Suggestions Add-on

1. Add a **GitLab Ultimate Self-Managed** subscription with a [Duo Pro subscription add-on](../../subscriptions/subscription-add-ons.md) to your GDK instance.

   [Self-purchase your own subscription](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/30a6670d39da223565081cbe46ba17d8e610aad1/doc/flows/buy_subscription.md#buy-subscription) for GitLab Ultimate Self-Managed from the [staging Customers Portal](https://customers.staging.gitlab.com).
   To do this, send a message to the `#s_fulfillment` or `s_fulfillment_engineering` Slack channels. The team will:

   - Give you instructions or set your account so you do not have to pay for a subscription.
   - Add the Duo Pro add-on to your account.

   After this step is complete, you will have an activation code for a _GitLab Ultimate Self-Managed subscription with a Duo Pro add-on_.

1. Follow the [activation instructions](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/doc/license/cloud_license.md?ref_type=heads#testing-activation):

   1. Set environment variables.

      ```shell
      export GITLAB_LICENSE_MODE=test
      export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
      export GITLAB_SIMULATE_SAAS=0
      ```

   1. Restart your GDK.
   1. Go to `/admin/subscription`.
   1. Optional. Remove any active license.
   1. Add the new activation code.

1. Inside your GDK, navigate to Admin Area > GitLab Duo Pro, go to `/admin/code_suggestions`
1. Filter users to find `root` and click the toggle to assign a GitLab Duo Pro add-on seat to the root user
