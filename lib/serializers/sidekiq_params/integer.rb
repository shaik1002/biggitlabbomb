# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class Integer < Serializers::SidekiqParams::Base
      def serialize
        @value.to_s
      end

      def self.parse(value)
        value.to_i
      end
    end
  end
end
