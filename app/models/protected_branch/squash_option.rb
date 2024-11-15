# frozen_string_literal: true

class ProtectedBranch::SquashOption < ApplicationRecord
  belongs_to :protected_branch
  belongs_to :project

  enum :setting, {
    never: 0,
    always: 1,
    default_on: 2,
    default_off: 3
  }, prefix: 'squash'

  validate :validate_protected_branch

  scope :for_all_protected_branches, -> { where(protected_branch_id: nil) }

  def for_all_protected_branches?
    protected_branch_id.nil?
  end

  def squash_enabled_by_default?
    %w[always default_on].include?(squash_option)
  end

  def squash_readonly?
    %w[always never].include?(squash_option)
  end

  private

  def validate_protected_branch
    return unless protected_branch&.wildcard?

    errors.add(:base, _('cannot configure squash options for wildcard'))
  end
end
