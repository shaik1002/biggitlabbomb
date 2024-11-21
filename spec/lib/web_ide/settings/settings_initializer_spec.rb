# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::SettingsInitializer, :web_ide_fast, feature_category: :web_ide do
  let(:all_possible_requested_setting_names) { WebIde::Settings::DefaultSettings.default_settings.keys }
  let(:context) do
    { requested_setting_names: all_possible_requested_setting_names }
  end

  subject(:returned_value) do
    described_class.init(context)
  end

  it "invokes DefaultSettingsParser and sets up necessary values in context for subsequent steps" do
    expect(returned_value).to match(
      {
        requested_setting_names: [:vscode_extensions_gallery, :vscode_extensions_gallery_metadata],
        settings: {
          vscode_extensions_gallery: {
            control_url: "",
            item_url: "https://open-vsx.org/vscode/item",
            nls_base_url: "",
            publisher_url: "",
            resource_url_template: "https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}",
            service_url: "https://open-vsx.org/vscode/gallery"
          },
          vscode_extensions_gallery_metadata: {}
        },
        setting_types: {
          vscode_extensions_gallery: Hash,
          vscode_extensions_gallery_metadata: Hash
        },
        env_var_prefix: "GITLAB_WEB_IDE",
        env_var_failed_message_class: WebIde::Settings::Messages::SettingsEnvironmentVariableOverrideFailed
      }
    )
  end
end
