# frozen_string_literal: true

module Repositories
  class ProtectedBranchDestroyedEvent < ::Gitlab::EventStore::Event
    PARENT_TYPES = {
      group: 'group',
      project: 'project'
    }.freeze

    def schema
      {
        'type' => 'object',
        'properties' => {
          'protected_branch_name' => { 'type' => 'string' },
          'parent_id' => { 'type' => 'integer' },
          'parent_type' => { 'type' => 'string', 'enum' => PARENT_TYPES.values }
        },
        'required' => %w[protected_branch_name parent_id parent_type]
      }
    end
  end
end
