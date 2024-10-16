# frozen_string_literal: true

class MemberEntity < Grape::Entity
  include RequestAwareEntity
  include AvatarsHelper

  expose :id
  expose :created_at
  expose :expires_at do |member|
    member.expires_at&.to_time
  end
  expose :requested_at

  expose :created_by,
    if: ->(member) { member.created_by.present? && member.is_source_accessible_to_current_user } do |member|
    UserEntity.represent(member.created_by, only: [:name, :web_url])
  end

  expose :can_update do |member|
    member.can_update?
  end

  expose :can_remove do |member|
    member.can_remove?
  end

  expose :last_owner?, as: :is_last_owner

  expose :is_direct_member do |member, options|
    member.source == options[:source]
  end

  expose :access_level do
    expose :human_access, as: :string_value
    expose :access_level, as: :integer_value
    expose :member_role_id
    expose :member_role_description, as: :description
  end

  expose :source, if: ->(member) { member.is_source_accessible_to_current_user } do |member|
    GroupEntity.represent(member.source, only: [:id, :full_name, :web_url])
  end

  expose :is_shared_with_group_private do |member|
    !member.is_source_accessible_to_current_user
  end

  expose :type

  expose :valid_level_roles, as: :valid_roles

  expose :valid_member_roles, as: :custom_roles

  expose :user, if: ->(member) { member.user.present? } do |member, options|
    MemberUserEntity.represent(member.user, options)
  end

  expose :state

  expose :invite, if: ->(member) { member.invite? } do
    expose :email do |member|
      member.invite_email
    end

    expose :avatar_url do |member|
      avatar_icon_for_email(member.invite_email, Member::AVATAR_SIZE)
    end

    expose :can_resend do |member|
      member.can_resend_invite?
    end

    expose :user_state do |member|
      member.respond_to?(:invited_user_state) ? member.invited_user_state : ""
    end
  end

  private

  def current_user
    options[:current_user]
  end
end

MemberEntity.prepend_mod_with('MemberEntity')
