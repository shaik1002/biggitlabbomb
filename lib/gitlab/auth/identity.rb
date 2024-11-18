# frozen_string_literal: true

module Gitlab
  module Auth
    ##
    # Gitlab::Auth::Identity class represents a user identity which is about to get authenticated using various
    # authentication methods we support in GitLab. It mimics `::User` class.
    #
    class Identity
      include ::Gitlab::Auth::User

      attr_reader :user, :scope

      delegate_missing_to :user

      class << self
        delegate_missing_to :User
      end

      def self.fabricate(identity, scope = nil)
        return if identity.nil?
        return identity if identity.is_a?(DeployToken) # TODO
        return identity if identity.is_a?(DeployKey)   # TODO

        case identity
        when ::Gitlab::Auth::Identity
          raise ArgumentError if scope != identity.scope

          new(identity.user, identity.scope)
        when ::User
          new(identity, scope)
        else
          binding.pry
          raise NotImplementedError
        end
      end

      def self.declarative_policy_class
        '::UserPolicy'
      end

      def initialize(identity, scope = nil)
        @user = identity
        @scope = scope
      end

      ##
      # Override equality check. See https://ruby-doc.org/3.3.6/BasicObject.html#method-i-3D-3D
      #
      def ==(other)
        return false if @scope.present?

        @user == other
      end
      alias_method :eql?, :==

      # override the default implementation
      def hash
        @user.hash
      end

      ##
      # TODO
      #
      def is_a?(klass)
        @user.is_a?(klass) || super
      end

      def devise_scope
        :user
      end

      def to_param
        @user.to_param
      end

      def identity
        @user
      end

      def to_user
        @user
      end

      def admin?
        @user.admin? # rubocop:disable Cop/UserAdmin -- TODO
      end

      def can?(action, subject = :global, **opts)
        ::Ability.allowed?(self, action, subject, **opts)
      end

      def access_locked?
        @user.access_locked?
      end

      def blocked?
        @user.blocked?
      end

      def deactivated?
        @user.deactivated?
      end

      def internal?
        @user.internal?
      end

      def confirmed?
        @user.confirmed?
      end
    end
  end
end
