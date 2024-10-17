# frozen_string_literal: true

module ProtectedRefDeployKeyAccess
  extend ActiveSupport::Concern

  included do
    belongs_to :deploy_key

    protected_ref_fk = "#{module_parent.model_name.singular}_id"
    validates :deploy_key_id, uniqueness: { scope: protected_ref_fk, allow_nil: true }
    validates :deploy_key, presence: true, if: :deploy_key_id
    validate :validate_deploy_key_membership, if: :deploy_key
  end

  class_methods do
    def non_role_types
      super << :deploy_key
    end
  end

  def type
    return :deploy_key if deploy_key_id.present? || deploy_key.present?

    super
  end

  def humanize
    return humanize_deploy_key if deploy_key?

    super
  end

  def check_access(current_user, current_project = project)
    super do
      break deploy_key_access_allowed?(current_user) if deploy_key?

      yield if block_given?
    end
  end

  private

  def humanize_deploy_key
    return deploy_key.title if deploy_key.present?

    'Deploy key'
  end

  def deploy_key?
    type == :deploy_key
  end

  def validate_deploy_key_membership
    return if deploy_key_has_write_access_to_project?

    errors.add(:deploy_key, 'is not enabled for this project')
  end

  def deploy_key_access_allowed?(current_user)
    deploy_key_owned_by?(current_user) && valid_deploy_key_status?
  end

  def deploy_key_owned_by?(current_user)
    deploy_key.user_id == current_user.id
  end

  def valid_deploy_key_status?
    deploy_key.user.can?(:read_project, project) &&
      deploy_key_owner_project_member? &&
      deploy_key_has_write_access_to_project?
  end

  def deploy_key_owner_project_member?
    project.member?(deploy_key.user)
  end

  def deploy_key_has_write_access_to_project?
    DeployKey.with_write_access_for_project(project, deploy_key: deploy_key).exists?
  end
end
