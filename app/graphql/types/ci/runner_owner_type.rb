# frozen_string_literal: true

module Types
  module Ci
    class RunnerOwnerType < BaseScalar
      graphql_name 'CiRunnerOwner'
      description 'Ci Runner Owner'

      OWNER_REGEX = %r{^(project/|group/|administrator$|none$)}

      def self.coerce_input(input_value, _context)
        unless input_value.match?(OWNER_REGEX)
          raise GraphQL::CoercionError, "#{input_value.inspect} is not a valid project name"
        end

        input_value
      end

      def self.coerce_result(ruby_value, _context)
        # It's transported as a string, so stringify it
        ruby_value.to_s
      end
    end
  end
end
