# frozen_string_literal: true

require "rainbow"

module Gitlab
  module Cng
    module Helpers
      # Console output helpers to include in command implementations
      #
      module Output
        LOG_COLOR = {
          default: nil,
          info: :magenta,
          success: :green,
          warn: :yellow,
          error: :red
        }.freeze

        private

        # Print colorized log message to stdout
        #
        # @param [String] message
        # @param [Symbol] type
        # @param [Boolean] bright
        # @return [void]
        def log(message, type = :default, bright: false)
          puts colorize(message, LOG_COLOR.fetch(type), bright: bright)
        end

        # Exit with non zero exit code and print error message
        #
        # @param [String] message
        # @return [void]
        def exit_with_error(message)
          log(message, :error, bright: true)
          exit 1
        end

        # Colorize message string and output to stdout
        #
        # @param [String] message
        # @param [<Symbol, nil>] color
        # @param [Boolean] bright
        # @return [String]
        def colorize(message, color, bright: false)
          rainbow.wrap(message)
            .then { |m| bright ? m.bright : m }
            .then { |m| color ? m.color(color) : m }
        end

        # Instance of rainbow colorization class
        #
        # @return [Rainbow]
        def rainbow
          @rainbow ||= Rainbow.new
        end
      end
    end
  end
end
