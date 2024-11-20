# frozen_string_literal: true

module Gitlab
  module Auth
    class UserPolicy < ::UserPolicy
      delegate { user }
    end
  end
end

Gitlab::Auth::UserPolicy.prepend_mod
