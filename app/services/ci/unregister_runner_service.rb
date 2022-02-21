# frozen_string_literal: true

module Ci
  class UnregisterRunnerService
    attr_reader :runner, :author

    # @param [Ci::Runner] runner the runner to unregister/destroy
    # @param [User, authentication token String] author the user or the authentication token that authorizes the removal
    def initialize(runner, author)
      @runner = runner
      @author = author
    end

    def execute
      @runner&.destroy
    end
  end
end

Ci::UnregisterRunnerService.prepend_mod
