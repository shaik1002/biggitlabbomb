# frozen_string_literal: true

module Gitlab
  module Auth
    ##
    # Gitlab::Auth::User class represents a user identity which is about to get authenticated using various
    # authentication methods we support in GitLab.
    #
    class User
      include GlobalID::Identification

      def initialize(identity, scope = nil)
        return unless identity

        case identity
        when self.class
          @user = identity.user
          @scope = identity.scope
          @scoped_user_id = @identity.scoped_user_id

          raise if @scope != scope # TODO
        when ::User
          @user = identity
          @scope = scope
          @scoped_user_id = find_user_id_from_scope
        else
          raise NotImplementedError
        end
      end

      def identity_type
        ::User
      end

      class << self
        delegate_missing_to :User
      end

      attr_reader :user, :scope

      delegate_missing_to :user
      delegate :to_param, :to_global_id, to: :user

      def ==(other)
        return other == user if other.is_a?(::User) && scope.nil?

        other.class <= self.class &&
          other.user == user &&
          other.scope == scope
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

      def can?(action, subject = :global, **opts)
        ::Ability.allowed?(user, action, subject, **opts) &&
          delegate_user_can(action, subject, **opts)
      end

      def delegate_user_can(action, subject, **opts)
        return true unless delegate_user

        ::Ability.allowed?(delegate_user, action, subject, **opts)
      end

      def delegate_user
        User.find(find_user_id_from_scope) if find_user_id_from_scope.presence
      end

      def find_user_id_from_scope
        return unless scope

        user_scope = scope.find { |item| item =~ /^user:\d+/ }
        user_scope&.match(/\d+/)&.[](0).to_i
      end
    end
  end
end
