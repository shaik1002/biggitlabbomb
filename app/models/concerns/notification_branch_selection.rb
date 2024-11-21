# frozen_string_literal: true

# Concern handling functionality around deciding whether to send notification
# for activities on a specified branch or not. Will be included in
# Integrations::Base::ChatNotification and PipelinesEmailService classes.

module NotificationBranchSelection
  extend ActiveSupport::Concern
  include ::Integrations::BranchProtectionLogic

  class_methods do
    def branch_choices
      [
        [_('All branches'), 'all'].freeze,
        [_('Default branch'), 'default'].freeze,
        [_('Protected branches'), 'protected'].freeze,
        [_('Default branch and protected branches'), 'default_and_protected'].freeze
      ].freeze
    end
  end

  def notify_for_branch?(data)
    ref_name = extract_ref_from_data(data)
    case branches_to_be_notified
    when "all"
      true
    when "default"
      default_branch?(ref_name)
    when "protected"
      protected_branch?(ref_name)
    when "default_and_protected"
      default_branch?(ref_name) || protected_branch?(ref_name)
    else
      false
    end
  end

  private

  def default_branch?(ref_name)
    ref_name == project.default_branch
  end

  def extract_ref_from_data(data)
    if data[:ref]
      Gitlab::Git.ref_name(data[:ref])
    else
      data.dig(:object_attributes, :ref)
    end
  end
end
