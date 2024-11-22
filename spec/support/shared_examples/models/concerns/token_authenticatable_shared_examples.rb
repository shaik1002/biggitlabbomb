# frozen_string_literal: true

# Expects a `token_field` variable
RSpec.shared_examples 'TokenAuthenticatable' do
  describe 'dynamically defined methods' do
    it { expect(described_class).to respond_to("find_by_#{token_field}") }
    it { is_expected.to respond_to(token_field) }
    it { is_expected.to respond_to("set_#{token_field}") }
    it { is_expected.to respond_to("ensure_#{token_field}") }
    it { is_expected.to respond_to("ensure_#{token_field}!") }
    it { is_expected.to respond_to("reset_#{token_field}!") }
    it { is_expected.to respond_to("#{token_field}_matches?") }
    it { is_expected.to respond_to("#{token_field}_expires_at") }
    it { is_expected.to respond_to("#{token_field}_expired?") }
    it { is_expected.to respond_to("#{token_field}_with_expiration") }
  end

  describe '.token_authenticatable_fields' do
    it 'includes the token field' do
      expect(described_class.token_authenticatable_fields).to include(token_field)
    end
  end
end
