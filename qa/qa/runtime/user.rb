# frozen_string_literal: true

module QA
  module Runtime
    # TODO: remove once all user handling logic is moved to UserStore class
    module User
      extend self

      def admin
        UserStore.admin_user
      end

      def default_username
        'root'
      end

      def default_email
        'admin@example.com'
      end

      def default_password
        Runtime::Env.initial_root_password || '5iveL!fe'
      end

      def username
        Runtime::Env.user_username || default_username
      end

      def password
        Runtime::Env.user_password || default_password
      end

      def email
        default_email
      end

      def admin_username
        Runtime::Env.admin_username || default_username
      end

      def admin_password
        Runtime::Env.admin_password || default_password
      end
    end
  end
end

QA::Runtime::User.extend_mod_with('Runtime::User', namespace: QA)
