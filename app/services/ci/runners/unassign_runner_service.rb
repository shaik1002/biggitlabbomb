# frozen_string_literal: true

module Ci
  module Runners
    class UnassignRunnerService
      # @param [Ci::RunnerProject] runner_project the runner/project association to destroy
      # @param [User] user the user performing the operation
      # @param [Hash] caller_info: information about calling API
      def initialize(runner_project, user, caller_info)
        @runner_project = runner_project
        @runner = runner_project.runner
        @project = runner_project.project
        @user = user
        @caller_info = caller_info
      end

      def execute
        unless @user.present? && @user.can?(:assign_runner, @runner)
          return ServiceResponse.error(message: 'user not allowed to assign runner')
        end

        if @runner_project.destroy
          ServiceResponse.success
        else
          ServiceResponse.error(message: 'failed to destroy runner project')
        end
      end

      private

      attr_reader :runner, :project, :user, :caller_info
    end
  end
end

Ci::Runners::UnassignRunnerService.prepend_mod
