# frozen_string_literal: true

module Gitlab
  module Metrics
    module SecurityScanSlis
      class << self
        def initialize_slis!
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:security_scan, possible_labels)
        end

        def error_rate
          Gitlab::Metrics::Sli::ErrorRate[:security_scan]
        end

        private

        def possible_labels
          security_parsers.map { |parser| { scan_type: parser } }
        end

        def security_parsers
          all_parsers.select { |_parser, klass| klass.module_parent == Gitlab::Ci::Parsers::Security }
                     .keys
                     .map(&:to_s)
        end

        def all_parsers
          Gitlab::Ci::Parsers.parsers
        end
      end
    end
  end
end
