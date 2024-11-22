# frozen_string_literal: true

RSpec.shared_context 'with token authenticatable routable token context' do
  let(:random_bytes) { 'a' * TokenAuthenticatableStrategies::RoutableTokenGenerator::RANDOM_BYTES_LENGTH }
  let(:devise_token) { 'devise-token' }

  before do
    allow(TokenAuthenticatableStrategies::RoutableTokenGenerator)
      .to receive(:random_bytes).with(TokenAuthenticatableStrategies::RoutableTokenGenerator::RANDOM_BYTES_LENGTH)
      .and_return(random_bytes)
    allow(Devise).to receive(:friendly_token).and_return(devise_token)
    allow(Settings).to receive(:cell).and_return({ id: 1 })
  end
end
