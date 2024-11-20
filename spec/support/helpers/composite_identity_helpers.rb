# frozen_string_literal: true

module CompositeIdentityHelpers
  def build_identity(user)
    return unless user
    return user if user.is_a?(::Gitlab::Auth::Identity)

    if ::Feature.enabled?(:api_composite_identity, user) && user.is_a?(User)
      ::Gitlab::Auth::Identity.new(user)
    else
      user
    end
  end
end
