# frozen_string_literal: true

module Packages
  class PackageCreatedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'name' => { 'type' => 'string' },
          'version' => { 'type' => %w[string null] },
          'package_type' => { 'type' => 'string', 'enum' => ::Packages::Package.package_types.keys },
          'id' => { 'type' => 'integer' },
          'user_id' => { 'type' => 'integer' }
        },
        'required' => %w[project_id id name package_type]
      }
    end

    def user_id
      data[:user_id]
    end

    def generic?
      data[:package_type] == 'generic'
    end

    def npm?
      data[:package_type] == 'npm'
    end
  end
end
