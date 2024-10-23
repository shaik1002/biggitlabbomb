# frozen_string_literal: true

module WorkItems
  module Widgets
    class EmailParticipants < Base
      delegate :email_participants_emails, to: :work_item

      def self.quick_action_commands
        [:add_email, :remove_email]
      end

      def self.quick_action_params
        [:emails]
      end
    end
  end
end
