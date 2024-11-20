# frozen_string_literal: true

module WorkItems
  class ParentLinkPolicy < BasePolicy
    condition(:parent_is_on_group) { @subject.work_item_parent.resource_parent.is_a?(Group) }
    condition(:child_is_on_group) { @subject.work_item_parent.resource_parent.is_a?(Group) }

    condition(:parent_is_on_project) { @subject.work_item_parent.resource_parent.is_a?(Project) }
    condition(:child_is_on_project) { @subject.work_item.resource_parent.is_a?(Project) }

    condition(:parent_read_work_item) { user.can?(:read_work_item, @subject.work_item_parent.namespace) }
    condition(:child_read_work_item) { user.can?(:read_work_item, @subject.work_item.namespace) }

    condition(:parent_guest_access) { user.can?(:guest_access, @subject.work_item_parent.namespace) }
    condition(:child_guest_access) { user.can?(:guest_access, @subject.work_item.namespace) }

    rule { (parent_is_on_group & child_is_on_group & parent_guest_access & child_guest_access) }.policy do
      enable :create_parent_link
    end

    rule { parent_is_on_group & child_is_on_project & parent_read_work_item & child_guest_access }.policy do
      enable :create_parent_link
    end

    rule { parent_is_on_project & child_is_on_project & parent_guest_access & child_guest_access }.policy do
      enable :create_parent_link
    end
  end
end
