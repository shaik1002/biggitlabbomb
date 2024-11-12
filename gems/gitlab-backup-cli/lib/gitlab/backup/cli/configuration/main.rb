# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Configuration
        class Main
          include Structure

          field :debug, type: :boolean, default_value: false
          field :log_level, type: :string, default_value: "info"
          #
          # section :storage do
          #   field :path, type: :string
          #   field :temp, type: :string
          #   field :owner, type: :string
          #   field :group, type: :string
          # end
          #
          # section :cloud do
          #   field :provider, type: :cloud_provider_keyword
          #
          #   # google GCP attributes
          #   field :google_project, type: :string
          #   field :google_json_key_location, type: :string
          #   field :google_json_key_string, type: :string
          # end
          #
          # section :postgresql do
          #   field :strategy, type: :string
          #   field :enabled, type: :boolean, default: true
          # end
          #
          # section :git do
          #   field :strategy, type: :string
          #   field :enabled, type: :boolean, default: true
          # end
          #
          # section :files do
          #   field :strategy, type: :string
          #   field :enabled, type: :boolean, default: true
          #
          # end
        end
      end
    end
  end
end
