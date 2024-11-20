# frozen_string_literal: true

module Gitlab
  module Auth
    ##
    # Gitlab::Auth::Identity class represents an authenticated user identity.
    #
    class Identity
      include ::Gitlab::Auth::User

      class << self
        delegate_missing_to :User

        def fabricate(identity, scope = nil)
          return if identity.nil?
          return identity if identity.is_a?(DeployToken) # TODO

          case identity
          when ::Gitlab::Auth::Identity
            raise ArgumentError if scope != identity.scope

            new(identity.user, identity.scope)
          when ::User
            new(identity, scope)
          else
            raise NotImplementedError
          end
        end
      end

      delegate_missing_to :user
      delegate :to_param, :to_global_id, to: :user

      attr_reader :user, :scope

      def initialize(identity, scope = nil)
        @user = identity
        @scope = scope
      end

      def ==(other)
        if other.is_a?(::User) && scope.nil?
          other == user
        else
          other.class <= self.class &&
            other.user == user &&
            other.scope == scope
        end
      end
      alias_method :eql?, :==

      def is_a?(klass)
        user.is_a?(klass) || super
      end

      # override the default implementation
      def hash
        return user.hash if scope.nil?

        super
      end

      def devise_scope
        :user
      end

      def identity_type
        ::User
      end

      def can?(action, subject = :global, **opts)
        ::Ability.allowed?(self, action, subject, **opts)
      end
    end
  end
end
