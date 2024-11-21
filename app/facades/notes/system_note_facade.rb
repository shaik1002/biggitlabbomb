# frozen_string_literal: true

module Notes
  class SystemNoteFacade
    TYPES_RESTRICTED_BY_PROJECT_ABILITY = {
      branch: :download_code
    }.freeze

    TYPES_RESTRICTED_BY_GROUP_ABILITY = {
      contact: :read_crm_contact
    }.freeze

    attr_reader :note

    def initialize(note)
      @note = note
    end

    def system_note_visible_for?(user)
      return system_note_visible_for_foss?(user) unless Gitlab.ee?

      system_note_visible_for_ee?(user)
    end

    def system_note_with_references?
      return unless note.system?

      if force_cross_reference_regex_check?
        note.matches_cross_reference_regex?
      else
        ::SystemNotes::IssuablesService.cross_reference?(note.note)
      end
    end

    private

    def created_before_noteable?
      note.created_at.to_i < note.noteable.created_at.to_i
    end

    def system_note_for_epic?
      note.system? && note.for_epic?
    end

    def system_note_viewable_by?(user)
      return true unless note.system_note_metadata

      system_note_viewable_by_project_ability?(user) && system_note_viewable_by_group_ability?(user)
    end

    def system_note_visible_for_ee?(user)
      return false unless system_note_visible_for_foss?(user)

      return true unless system_note_for_epic? && created_before_noteable?

      group_reporter?(user, note.noteable.group)
    end

    def system_note_visible_for_foss?(user)
      return true unless note.system?

      system_note_viewable_by?(user) && all_referenced_mentionables_allowed?(user)
    end

    def all_referenced_mentionables_allowed?(user)
      return true unless system_note_with_references?

      if note.user_visible_reference_count.present? && note.total_reference_count.present?
        # if they are not equal, then there are private/confidential references as well
        note.user_visible_reference_count > 0 && note.user_visible_reference_count == note.total_reference_count
      else
        refs = note.all_references(user)

        refs.all.present? && refs.all_visible?
      end
    end

    def force_cross_reference_regex_check?
      note
        .system_note_metadata
        &.cross_reference_types
        &.include?(note.system_note_metadata&.action)
    end

    def group_reporter?(user, group)
      group.max_member_access_for_user(user) >= ::Gitlab::Access::REPORTER
    end

    def system_note_viewable_by_project_ability?(user)
      project_restriction = TYPES_RESTRICTED_BY_PROJECT_ABILITY[note.system_note_metadata.action.to_sym]
      !project_restriction || Ability.allowed?(user, project_restriction, note.project)
    end

    def system_note_viewable_by_group_ability?(user)
      group_restriction = TYPES_RESTRICTED_BY_GROUP_ABILITY[note.system_note_metadata.action.to_sym]
      !group_restriction || Ability.allowed?(user, group_restriction, note.project&.group)
    end
  end
end
