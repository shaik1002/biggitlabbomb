# frozen_string_literal: true

FactoryBot.define do
  factory :container_registry_tag_protection_rule, class: 'ContainerRegistry::TagProtection::Rule' do
    project
    tag_name_pattern { 'v.+' }
    minimum_access_level_for_delete { :maintainer }
    minimum_access_level_for_push { :maintainer }
  end
end
