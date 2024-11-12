# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Configuration
        module Structure
          Field = Data.define(:name, :type, :default_value) do
            def define_predicate? = self.type == :boolean
            def define_reader? = true
            def define_writer? = !nested_configuration?
            def has_default_value? = !default_value.nil?
            def nested_configuration? = self.type == :nested_configuration

            def constant_name = name.to_s.camelize.to_sym
            def instance_variable = :"@#{name}"
            def predicate_name = :"#{name}?"
            def reader_name = name.to_sym
            def writer_name = :"#{name}="

            def resolve_default_value(instance_object)
              if default_value.is_a?(Proc)
                instance_object.instance_exec(&default_value)
              else
                default_value
              end
            end
          end
        end
      end
    end
  end
end
