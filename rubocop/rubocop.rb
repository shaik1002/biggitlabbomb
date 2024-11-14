# rubocop:disable Naming/FileName
# frozen_string_literal: true

# Load ActiveSupport to ensure that core extensions like `Enumerable#exclude?`
# are available in cop rules like `Performance/CollectionLiteralInLoop`.
require 'active_support/all'

# Auto-require all cops under `rubocop/cop/**/*.rb`
Dir[File.join(__dir__, 'cop', '**', '*.rb')].each { |file| require file }
# $histo = []

module Patch
  class FilePattern
    @cache = {}.compare_by_identity

    def self.from(patterns)
      @cache[patterns] ||= new(patterns)
    end

    def initialize(patterns)
      @matchers = group_by_type(patterns)
        .map { |klass, matched| build_matcher(klass, matched) } 
        .sort_by(&:cost)

      p got: @matchers.map(&:class)
    end

    def match?(path)
      @matchers.any? { |matcher| matcher.matches?(path) }
    end

    def group_by_type(patterns)
      patterns
        .filter_map { |pattern| matcher_for(pattern) }
        .group_by { |klass, _| klass }
    end

    def build_matcher(klass, matched)
      args = matched.flat_map { |_, *a| a }
      p klass => args
      klass.new(args)
    end

    def matcher_for(pattern)
      case pattern
      when String
        case pattern
        when %r{^\*\*(/[\w/]+/)\*\*/\*$}
          [MiddleMatch, $1]
        when %r{^\*\*/\*([\w.]+)$}
          [EndMatch, $1]
        when %r{^(/?[\w/]+/)\*\*/\*(\.\w+)$}
          [StartEndMatch, $1, $2]
        when %r{^(/?[\w/]+/)\*\*/\*$}
          [StartMatch, $1]
        when /[*{}]/
          # $histo << pattern.gsub(/\w+/, 'x').gsub(/(x\/)+/, 'x/')
          [FileMatch, pattern]
        else
          [ExactMatch, pattern]
        end
      else
        [FileMatch, pattern]
      end
    end

    class ExactMatch
      def initialize(patterns)
        @patterns = patterns.to_set
      end

      def matches?(path)
        @patterns.include?(path)
      end

      def cost
        1
      end
    end

    class MiddleMatch
      def initialize(middles)
        @middles = middles
      end

      def matches?(path)
        @middles.any? do |e|
          path.include?(e)
        end
      end

      def cost
        3
      end
    end

    class EndMatch
      def initialize(ends)
        @ends = ends
      end

      def matches?(path)
        p @ends
        @ends.any? do |e|
          path.end_with?(e)
        end
      end

      def cost
        3
      end
    end

    class StartMatch
      def initialize(starts)
        @starts = starts
      end

      def matches?(path)
        @starts.any? do |s|
          path.start_with?(s)
        end
      end

      def cost
        3
      end
    end

    class StartEndMatch
      def initialize(start_ends)
        @start_ends = start_ends
      end

      def matches?(path)
        @start_ends.any? do |s, e|
          path.start_with?(s) && path.end_with?(e)
        end
      end

      def cost
        3
      end
    end

    class FileMatch
      def initialize(patterns)
        @patterns = patterns
      end

      def matches?(path)
        @patterns.any? do |pattern|
          RuboCop::PathUtil.match_path?(pattern, path)
        end
      end

      def cost
        10
      end
    end
  end
end

RuboCop.const_set(:FilePatterns, Patch::FilePattern)

at_exit do
  # pp $histo.tally.sort_by { |k, v| -v }
end

# rubocop:enable Naming/FileName
