# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Releaser
        CREATE_BASE_COMMAND = 'release-cli create'
        CREATE_SINGLE_FLAGS = %i[name description tag_name tag_message ref released_at].freeze
        CREATE_ARRAY_FLAGS = %i[milestones].freeze

        GLAB_LOGIN_COMMAND = 'glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL'
        GLAB_MAIN_COMMAND = 'GITLAB_HOST=$CI_SERVER_URL glab -R $CI_PROJECT_PATH'
        GLAB_CREATE_COMMAND = "#{GLAB_MAIN_COMMAND} release create".freeze
        GLAB_PUBLISH_TO_CATALOG_FLAG = '--publish-to-catalog'

        attr_reader :job, :config

        def initialize(job:)
          @job = job
          @config = job.options[:release]
        end

        def script
          if catalog_publish?
            [GLAB_LOGIN_COMMAND, glab_create_command_with_publish_to_catalog]
          else
            [create_command]
          end
        end

        private

        def create_command
          command = CREATE_BASE_COMMAND.dup
          create_single_flags.each { |k, v| command.concat(" --#{k.to_s.dasherize} \"#{v}\"") }
          create_array_commands.each { |k, v| v.each { |elem| command.concat(" --#{k.to_s.singularize.dasherize} \"#{elem}\"") } }
          create_asset_links.each { |link| command.concat(" --assets-link #{stringified_json(link)}") }
          command.freeze
        end

        def glab_create_command_with_publish_to_catalog
          command = GLAB_CREATE_COMMAND.dup
          command.concat(" \"#{config[:tag_name]}\"")
          command.concat(" --assets-links #{stringified_json(create_asset_links)}") if create_asset_links.present?
          command.concat(" --milesone \"#{config[:milestones].join(',')}\"") if config[:milestones].present?
          command.concat(" --name \"#{config[:name]}\"") if config[:name].present?
          command.concat(" --notes \"#{config[:description]}\"") if config[:description].present?
          command.concat(" --ref \"#{config[:ref]}\"") if config[:ref].present?
          command.concat(" --tag-message \"#{config[:tag_message]}\"") if config[:tag_message].present?
          command.concat(" --released-at \"#{config[:released_at]}\"") if config[:released_at].present?
          command.concat(" #{GLAB_PUBLISH_TO_CATALOG_FLAG}")
          command.freeze
        end

        def create_single_flags
          config.slice(*CREATE_SINGLE_FLAGS)
        end

        def create_array_commands
          config.slice(*CREATE_ARRAY_FLAGS)
        end

        def create_asset_links
          config.dig(:assets, :links) || []
        end

        def stringified_json(object)
          object.to_json.to_json.to_s
        end

        def catalog_publish?
          # TODO: disable first!
          return false if ::Feature.disabled?(:ci_release_cli_catalog_publish_option, job.project)

          job.project.catalog_resource
        end
      end
    end
  end
end
