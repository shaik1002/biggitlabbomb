# frozen_string_literal: true

module Inertia
  module Share
    extend ActiveSupport::Concern

    included do
      layout "inertia"

      inertia_share sidebarData: -> { sidebar_data }
    end

    def sidebar_data
      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- Demo shortcut. See TODO below.
      group = @parent_group || @group
      # TODO: Currently all existing Inertia pages are part of the "Your work" dashboard pages.
      # So hardcoding the "nav" panel name here works for now.
      # Later on, when pages with different sidebars would be added, this should be changed.
      # We could either make this info of the page props (or shared_data, possibly controlled by the Rails controllers),
      # or, use a nested folder structure in the inertia/Pages folder. All "Your work" dashboard pages
      # could live in a folder called "inertia/Pages/Dashboard".
      nav = "your_work"

      sidebar_panel = helpers.super_sidebar_nav_panel(nav: nav, user: current_user, group: group, project: @project,
        current_ref: @current_ref, ref_type: @ref_type, viewed_user: @user)
      helpers.super_sidebar_context(current_user, group: group, project: @project, panel: sidebar_panel,
        panel_type: nav)
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
