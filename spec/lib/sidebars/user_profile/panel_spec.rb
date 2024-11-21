# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Panel, feature_category: :navigation do
  let(:current_user) { build_stubbed(:user) }
  let(:user) { build_stubbed(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }

  subject { described_class.new(context) }

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'

  it 'implements #aria_label' do
    expect(subject.aria_label).to eq(s_('UserProfile|User profile navigation'))
  end

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq(_('Profile'))
  end
end
