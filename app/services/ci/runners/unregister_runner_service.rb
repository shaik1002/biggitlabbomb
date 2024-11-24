# frozen_string_literal: true

module Ci
  module Runners
    class UnregisterRunnerService
      attr_reader :runner, :author, :caller_info

      # @param [Ci::Runner] runner the runner to unregister/destroy
      # @param [User, authentication token String] author the user or the authentication token that authorizes the removal
      # @param [Hash] caller_info: information about calling API
      def initialize(runner, author, caller_info)
        @runner = runner
        @author = author
        @caller_info = caller_info
      end

      def execute
        runner.destroy!

        ServiceResponse.success
      end
    end
  end
end

Ci::Runners::UnregisterRunnerService.prepend_mod
