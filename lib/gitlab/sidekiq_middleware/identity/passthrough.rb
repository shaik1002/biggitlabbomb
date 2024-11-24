# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Identity
      class Passthrough
        include Sidekiq::ClientMiddleware

        SIDEKIQ_COMPOSITE_IDENTITY_ARG = 'sidekiq_scoped_identity'

        def call(_worker_class, job, _queue, _redis_pool)
          users = ::Gitlab::Auth::Identity.composite_identities

          raise ::Gitlab::Auth::Identity::TooManyIdentitiesLinkedError if users.size > 1

          ::Gitlab::Auth::Identity.new(users.first).tap do |identity|
            if identity.composite?
              job[SIDEKIQ_COMPOSITE_IDENTITY_ARG] = [identity.primary_user_id, identity.scoped_user_id]
            end
          end

          yield
        end
      end
    end
  end
end
