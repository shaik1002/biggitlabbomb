# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class TodosMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :link
        def link
          vue_dashboard_todos_path
        end

        override :title
        def title
          _('To-Do List')
        end

        override :sprite_icon
        def sprite_icon
          'todo-done'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { path: 'dashboard/todos#vue' }
        end

        override :has_pill?
        def has_pill?
          pill_count > 0
        end

        override :pill_count
        def pill_count
          context.current_user.todos_pending_count
        end
        strong_memoize_attr :pill_count

        override :inertia_page?
        def inertia_page?
          true
        end
      end
    end
  end
end
