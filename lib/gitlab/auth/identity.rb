# frozen_string_literal: true

module Gitlab
  module Auth
    ##
    # Identity class represents identity which we want to use in authorization policies.
    #
    # It decides if an identity is a single or composite identity and finds identity scope.
    #
    class Identity
      COMPOSITE_IDENTITY_USERS_KEY = 'composite_identities'
      COMPOSITE_IDENTITY_KEY = 'user:%s:composite_identity'

      IdentityError = Class.new(StandardError)
      IdentityLinkMismatchError = Class.new(IdentityError)
      UnexpectedIdentityError = Class.new(IdentityError)
      TooManyIdentitiesLinkedError = Class.new(IdentityError)

      def self.build_from_oauth_token(oauth_token)
        ##
        # TODO why is this method called 3 times in the spec?
        #
        # TODO we need to check respond_to? here because this method is not implemented yet
        #
        return oauth_token.user unless oauth_token.respond_to?(:scope_user)

        ::Gitlab::Auth::Identity
          .new(oauth_token.user)
          .link!(oauth_token.scope_user)

        oauth_token.user
      end

      def self.composite_identities
        ::Gitlab::SafeRequestStore
          .store[COMPOSITE_IDENTITY_USERS_KEY] ||= []
      end

      def initialize(user)
        @user = user

        @key = user.is_a?(User) ? format(COMPOSITE_IDENTITY_KEY, user.id) : 0
      end

      def composite?
        return false unless @user.is_a?(::User)

        @user.has_composite_identity?
      end

      def link!(user)
        raise UnexpectedIdentityError unless user.is_a?(User)

        if scoped_user_present? && scoped_user_id != user.id # rubocop:disable Style/IfUnlessModifier -- readability
          raise IdentityLinkMismatchError
        end

        identities = self.class.composite_identities.push(@user)

        if identities.size > 1
          # TODO log this unexpected situation
        end

        ::Gitlab::SafeRequestStore.store[@key] = user
      end

      def scoped_user_id
        scoped_user.id
      end

      def scoped_user
        ::Gitlab::SafeRequestStore.fetch(@key) do
          raise ArgumentError, 'composite identity missing'
        end
      end

      def scoped_user_present?
        ::Gitlab::SafeRequestStore.exist?(@key)
      end
    end
  end
end
