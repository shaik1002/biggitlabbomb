# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::AuthFinders, feature_category: :system_access do
  include described_class
  include HttpBasicAuthHelpers

  include_examples 'Auth::AuthFinders authenticates the user' do
    let(:identity) { ::Gitlab::Auth::User.new(user) }
    let(:nil_matcher) { eq(::Gitlab::Auth::User.new(nil)) }
  end

  context 'with api_composite_identity feature flag disabled' do
    before do
      stub_feature_flags(api_composite_identity: false)
    end

    include_examples 'Auth::AuthFinders authenticates the user' do
      let(:identity) { user }
      let(:nil_matcher) { be_nil }
    end
  end
end
