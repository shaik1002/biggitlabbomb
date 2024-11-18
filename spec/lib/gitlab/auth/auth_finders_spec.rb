# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::AuthFinders, feature_category: :system_access do
  include described_class
  include HttpBasicAuthHelpers

  include_examples 'Auth::AuthFinders authenticates the user'
end
