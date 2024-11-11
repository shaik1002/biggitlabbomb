# frozen_string_literal: true

class ProtectedBranch::CacheKey # rubocop:disable Style/ClassAndModuleChildren -- Same problem as in push_access_level.rb
  include Gitlab::Utils::StrongMemoize

  CACHE_ROOT_KEY = 'cache:gitlab:protected_branch'

  def initialize(entity)
    @entity = entity
  end

  def to_s
    need_to_scope? ? scoped_key : unscoped_key
  end

  private

  attr_reader :entity

  def need_to_scope?
    Feature.enabled?(:group_protected_branches, group) ||
      Feature.enabled?(:allow_protected_branches_for_group, group)
  end

  def scoped_key
    [CACHE_ROOT_KEY, entity_scope, entity.id].join(':')
  end

  def unscoped_key
    [CACHE_ROOT_KEY, entity.id].join(':')
  end

  def group
    return entity if entity.is_a?(Group)
    return entity.group if entity.is_a?(Project)

    nil
  end
  strong_memoize_attr :group

  def entity_scope
    case entity
    when Group
      'group'
    when Project
      'project'
    else
      entity.class.name.downcase
    end
  end
end
