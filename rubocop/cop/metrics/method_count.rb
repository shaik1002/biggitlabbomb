# frozen_string_literal: true

require 'pathname'

module RuboCop
  module Cop
    module Metrics
      # TODO docs
      #
      # See https://docs.gitlab.com/ee/development/software_design.html#taming-omniscient-classes
      class MethodCount < RuboCop::Cop::Base
        include RuboCop::Cop::RangeHelp

        def on_new_investigation
          @methods = 0
          @namespaces = []
        end

        def on_class(node)
          @node = node
          @namespaces.concat identifiers_for(node)
        end

        def on_module(node)
          @node = node
          @namespaces.concat identifiers_for(node)
        end

        def on_def(_node)
          @methods += 1
        end

        def on_sdef(_node)
          @methods += 1
        end

        def on_investigation_end
          name = (@name || @namespaces).join('::')

          local_limit = exception_limit_for(name)
          limit = local_limit || global_limit

          if @methods > limit
            write_exception_limit(name, @methods)
            limit_increased(name, @methods)
          elsif @methods < limit
            if local_limit
              if @methods <= global_limit
                remove_exception_config(name)
                limit_undercut(name, @methods, global_limit)
              else
                write_exception_limit(name, @methods)
                limit_decreased(name, @methods, local_limit)
              end
            end
          end
        end

        def external_dependency_checksum
          Digest::SHA256.file(exceptions_file).hexdigest if exceptions_file.exist?
        end

        private

        def limit_increased(name, methods)
          range = @node || range_between(0, 1)

          message = <<~MSG.tr("\n", ' ').chomp
            `#{name}` has too many methods (#{methods} found only #{global_limit} allowed).
            Consider refactoring this class or commit the updated config.
            See https://docs.gitlab.com/ee/development/software_design.html#taming-omniscient-classes
          MSG

          add_offense(range, message: message)
        end

        def limit_decreased(name, methods, limit)
          range = @node || range_between(0, 1)

          message = <<~MSG.tr("\n", ' ').chomp
            `#{name}` has less methods than configured (#{limit} -> #{methods}).
            Keep it up! Config was updated. Please commit it.
            See https://docs.gitlab.com/ee/development/software_design.html#taming-omniscient-classes
          MSG

          add_offense(range, message: message, severity: :info)
        end

        def limit_undercut(name, methods, limit)
          range = @node || range_between(0, 1)

          message = <<~MSG.tr("\n", ' ').chomp
            `#{name}` undercut the limit of allowed methods (#{limit} -> #{methods})).
            Hooray! Config was removed. Please commit it.
            See https://docs.gitlab.com/ee/development/software_design.html#taming-omniscient-classes
          MSG

          add_offense(range, message: message, severity: :info)
        end

        def write_exception_limit(name, limit)
          self.class.cached_exceptions = nil # reload
          config = exceptions[name] ||= { 'Reason' => 'TODO: Link issue to reduce method count.' }
          config['Limit'] = limit

          write_exceptions
        end

        def remove_exception_config(name)
          self.class.cached_exceptions = nil # reload
          exceptions.delete(name)

          write_exceptions
        end

        def identifiers_for(node)
          node.identifier.source.sub(/^::/, '').split('::')
        end

        def global_limit
          @global_limit ||= cop_config.fetch('Limit', 100)
        end

        def exception_limit_for(name)
          exceptions.dig(name, 'Limit')
        end

        def exceptions
          exceptions = self.class.cached_exceptions
          return exceptions if exceptions

          self.class.cached_exceptions =
            if exceptions_file.exist?
              YAML.load_file(exceptions_file) || {}
            else
              {}
            end
        end

        def exceptions_file
          Pathname(cop_config.fetch('ExceptionsFile', '.rubocop-metrics-count-exceptions.yml'))
        end

        def write_exceptions
          sorted = exceptions.sort_by { |_name, hash| -hash['Limit'] }.to_h
          File.write(exceptions_file, YAML.dump(sorted))
        end

        class << self
          attr_accessor :cached_exceptions
        end
      end
    end
  end
end
