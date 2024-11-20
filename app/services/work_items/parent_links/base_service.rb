# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class BaseService < IssuableLinks::CreateService
      extend ::Gitlab::Utils::Override

      private

      def set_parent(issuable, work_item)
        link = WorkItems::ParentLink.for_work_item(work_item)
        link.work_item_parent = issuable
        link
      end

      def create_notes(work_item)
        SystemNoteService.relate_work_item(issuable, work_item, current_user)
      end

      def linkable_issuables(work_items)
        @linkable_issuables ||= if can?(current_user, :read_work_item, issuable)
                                  work_items.select { |work_item| linkable?(work_item) }
                                else
                                  []
                                end
      end

      def linkable?(work_item)
        can_create_link?(WorkItems::ParentLink.new(work_item_parent: issuable, work_item: work_item)) &&
          previous_related_issuables.exclude?(work_item)
      end

      def can_create_link?(work_item_link)
        can?(current_user, :create_parent_link, work_item_link)
      end

      def can_admin_link?(work_item)
        can?(current_user, :admin_parent_link, work_item)
      end

      override :previous_related_issuables
      def previous_related_issuables
        @previous_related_issuables ||= issuable.work_item_children.to_a
      end

      override :target_issuable_type
      def target_issuable_type
        'work item'
      end

      override :issuables_not_found_message
      def issuables_not_found_message
        format(_('No matching %{issuable} found. Make sure that you are adding a valid %{issuable} ID.'),
          issuable: target_issuable_type)
      end
    end
  end
end

WorkItems::ParentLinks::BaseService.prepend_mod
