# frozen_string_literal: true

module Gitlab
  module Auth
    ##
    # Gitlab::Auth::User module is a common ancestor of `Gitlab::Auth::Identity` and `::User` classes. Used primarly for
    # checks like `if user.is_a?(::Gitlab::Auth::User)` which returns `true` for both classes, as both mix
    # `Gitlab::Auth::User` in.
    #
    module User
      def identity_type
        ::User
      end

      def identity
        self
      end

      def self.fabricate(identity, scope = nil)
        ::Gitlab::Auth::Identity
          .fabricate(identity, scope)
      end
    end
  end
end
