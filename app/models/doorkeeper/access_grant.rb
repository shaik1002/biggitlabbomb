# frozen_string_literal: true

module Doorkeeper # rubocop:disable Gitlab/NamespacedClass,Gitlab/BoundedContexts -- Override from a gem
  class AccessGrant < ApplicationRecord
    include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant
    include SafelyChangeColumnDefault

    columns_changing_default :organization_id

    has_one :openid_request,
      class_name: 'Doorkeeper::OpenidConnect::Request',
      inverse_of: :access_grant
  end
end
