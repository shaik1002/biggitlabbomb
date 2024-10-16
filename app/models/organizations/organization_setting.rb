# frozen_string_literal: true

module Organizations
  class OrganizationSetting < ApplicationRecord
    belongs_to :organization

    validates :settings, json_schema: { filename: "organization_settings" }

    jsonb_accessor :settings,
      restricted_visibility_levels: [:integer, { array: true }]

    validates_each :restricted_visibility_levels do |record, attr, value|
      value&.each do |level|
        unless Gitlab::VisibilityLevel.options.value?(level)
          record.errors.add(attr, format(_("'%{level}' is not a valid visibility level"), level: level))
        end
      end
    end

    def self.for(organization_id)
      return unless organization_id

      Organizations::OrganizationSetting.find_or_initialize_by(organization_id: organization_id)
    end
  end
end
