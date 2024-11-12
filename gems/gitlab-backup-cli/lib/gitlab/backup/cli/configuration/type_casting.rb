# frozen_string_literal: true
require 'time'

module Gitlab
  module Backup
    module Cli
      module Configuration
        module TypeCasting
          module_function

          # Given a primitive +value+ loaded from a file, cast it to the
          # expected class as specified by +type+
          #
          # @param [Symbol] type
          # @param [Object] value
          # @return [Object] the parsed and converted value
          def cast_value(type:, value:)
            return value if value.nil?

            case type
            when :string then cast_string(value)
            when :time then cast_time(value)
            when :integer then cast_integer(value)
            else
              raise ArgumentError, "Unknown data type key #{type.inspect} provided when parsing backup metadata"
            end
          end

          # @param [String|Integer|Object] value
          def cast_string(value)
            value.to_s
          end

          def cast_time(value)
            return value if value.nil?

            begin
              Time.parse(value.to_s)
            rescue ArgumentError
              nil
            end
          end

          def cast_integer(value)
            return value if value.is_a?(Integer) || value.nil?

            value.to_s.to_i
          end
        end
      end
    end
  end
end
