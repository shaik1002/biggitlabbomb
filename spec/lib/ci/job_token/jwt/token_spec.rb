# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::JobToken::Jwt::Token, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:dummy_class) { Class.new { extend ::Ci::JobToken::Jwt::Token } }

  shared_examples 'tracks an error and returns nil' do |error_type|
    it 'tracks an error and returns nil' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(error_type))
      expect(result).to be_nil
    end
  end

  describe '.expected_type' do
    subject(:expected_type) { dummy_class.expected_type }

    it { is_expected.to eq(::Ci::Build) }
  end

  describe '.key' do
    subject(:result) { dummy_class.key }

    before do
      dummy_class.clear_memoization(:key)
    end

    it { is_expected.to be_an_instance_of(OpenSSL::PKey::RSA) }

    context 'when signing key is not set' do
      before do
        allow(Rails.application.credentials)
          .to receive(:ci_job_token_signing_key)
          .and_return(nil)
      end

      it_behaves_like 'tracks an error and returns nil', OpenSSL::PKey::RSAError
    end

    context 'when signing key is not a valid key' do
      before do
        allow(Rails.application.credentials)
          .to receive(:ci_job_token_signing_key)
          .and_return('invalid_key')
      end

      it_behaves_like 'tracks an error and returns nil', OpenSSL::PKey::RSAError
    end
  end

  describe '.token_prefix' do
    subject(:token_prefix) { dummy_class.token_prefix }

    it { is_expected.to eq(::Ci::Build::TOKEN_PREFIX) }
  end
end
