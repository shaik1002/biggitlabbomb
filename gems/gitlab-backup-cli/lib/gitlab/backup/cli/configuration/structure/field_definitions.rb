# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Configuration
        module Structure
          module FieldDefinitions
            extend ActiveSupport::Concern
            include ActiveModel::AttributeMethods

            module ClassMethods
              def field_registry
                @field_registry ||= {}
              end

              def field(
                name,
                type: :string,
                default_value: nil,
                &default_value_proc
              )
                default_value ||= default_value_proc
                field_spec = Field.new(
                  name: name.to_sym,
                  type: type,
                  default_value: default_value
                )

                register_field(field_spec)
                define_field_accessors(field_spec)
                define_attribute_methods field_spec.name

                #attribute name, type, default: default_value || default_value_proc
              end

              def field_names
                field_registry.keys
              end

              private

              def define_field_accessors(field_spec)
                ivar = field_spec.instance_variable

                if field_spec.define_reader?
                  define_method(field_spec.reader_name) do
                    unless instance_variable_defined?(ivar)
                      default_value = field_spec.resolve_default_value(self)
                      instance_variable_set(ivar, default_value)
                    end

                    instance_variable_get(ivar)
                  end
                end

                if field_spec.define_writer?
                  attr_writer field_spec.name
                end

                if field_spec.define_predicate?
                  define_method(field_spec.predicate_name) do
                    !!send(field_spec.reader_name)
                  end
                end

                self
              end

              def register_field(field_spec)
                field_registry[field_spec.name] = field_spec
              end
            end
          end
        end
      end
    end
  end
end
