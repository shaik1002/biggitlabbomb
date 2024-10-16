# frozen_string_literal: true

module Banzai
  module Pipeline
    class PlainMarkdownPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::MarkdownPreEscapeLegacyFilter,
          Filter::DollarMathPreLegacyFilter,
          Filter::BlockquoteFenceLegacyFilter,
          Filter::MarkdownFilter,
          Filter::DollarMathPostLegacyFilter,
          Filter::MarkdownPostEscapeLegacyFilter
        ]
      end
    end
  end
end
