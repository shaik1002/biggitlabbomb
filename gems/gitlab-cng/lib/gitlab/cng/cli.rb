# frozen_string_literal: true

require "thor"
require "require_all"

require_rel "lib/**/*.rb"
require_rel "commands/**/*.rb"

module Gitlab
  module Cng
    # Main CLI class handling all commands
    #
    class CLI < Commands::Command
      extend Helpers::Thor

      # Error raised by this runner
      Error = Class.new(StandardError)

      # Exit with non 0 status code if any command fails
      #
      # @return [Boolean]
      def self.exit_on_failure?
        true
      end

      register_commands(Commands::Version)
      register_commands(Commands::Doctor)

      desc "create [SUBCOMMAND]", "Manage deployment related object creation"
      subcommand "create", Commands::Create
    end
  end
end
