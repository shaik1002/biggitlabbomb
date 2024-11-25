# frozen_string_literal: true

module Gitlab
  module Graphql
    module Deprecations
      class Headers
        HEADER_FORMAT = '299 GitLab-GraphQL %{type}-%{schema_type}: [%{items}]'

        class << self
          def set(response)
            new(response).set_headers
          end
        end

        def initialize(response)
          @response = response
          @warnings = Array(response.headers['Warning'])

          usage_analyzer_result = Gitlab::Graphql::QueryAnalyzers::SchemaUsageAnalyzer.result
          @deprecated_arguments = usage_analyzer_result[:used_deprecated_arguments]
          @deprecated_fields = usage_analyzer_result[:used_deprecated_fields]
          @experimental_arguments = usage_analyzer_result[:used_experimental_arguments]
          @experimental_fields = usage_analyzer_result[:used_experimental_fields]
        end

        def set_headers
          collect_warnings(deprecated_fields, 'Deprecated', 'Fields')
          collect_warnings(experimental_fields, 'Experimental', 'Fields')
          # Not for our frontend?
          collect_warnings(deprecated_arguments, 'Deprecated', 'Arguments')
          collect_warnings(experimental_arguments, 'Experimental', 'Arguments')

          return unless warnings.present?

          all_warnings = Array(response.headers['Warning'])
          all_warnings.push(warnings)

          response.set_header('Warning', all_warnings)
          response.set_header('Deprecation', true) if deprecations? # TODO check the header spec

          response
        end

        private

        attr_reader :response, :usage_analyzer_result, :warnings,
          :deprecated_arguments, :deprecated_fields, :experimental_arguments, :experimental_fields

        def deprecations?
          deprecated_arguments.present? || deprecated_fields.present?
        end

        def collect_warnings(data, type, schema_type)
          return unless data.present?

          warnings << format(
            HEADER_FORMAT,
            type: type,
            schema_type: schema_type,
            items: data.join(',')
          )
        end
      end
    end
  end
end
