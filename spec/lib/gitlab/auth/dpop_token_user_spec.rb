# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::DpopTokenUser, feature_category: :system_access do
  include Auth::DpopTokenHelper

  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:personal_access_token, freeze: true) { create(:personal_access_token, user: user) }

  let(:personal_access_token_plaintext) { personal_access_token.token }

  let(:ath) { nil }
  let(:public_key_in_jwk) { nil }
  let(:dpop_token) do
    Gitlab::Auth::DpopToken.new(data: generate_dpop_proof_for(user, ath: ath,
      public_key_in_jwk: public_key_in_jwk).proof)
  end

  describe '#validate!' do
    subject(:validate!) do
      described_class.new(token: dpop_token, user: user,
        personal_access_token_plaintext: personal_access_token_plaintext).validate!
    end

    context 'when the token is valid' do
      it 'initializes with valid token' do
        expect { validate! }.not_to raise_error
      end
    end

    context "when an input isn't valid" do
      context 'when the DPoP token is invalid' do
        let(:dpop_token) { Gitlab::Auth::DpopToken.new(data: 'invalid') }

        it 'raises DpopValidationError' do
          expect do
            validate!
          end.to raise_error(Gitlab::Auth::DpopValidationError,
            /Malformed JWT, unable to decode. Not enough or too many segments/)
        end
      end

      context "when the PAT doesn't belong to the user" do
        let(:personal_access_token_plaintext) { 'invalid' }

        it 'raises DpopValidationError' do
          expect do
            validate!
          end.to raise_error(Gitlab::Auth::DpopValidationError,
            /Personal access token does not belong to the requesting user/)
        end
      end

      context "when the DPoP token isn't valid for the user" do
        context "when the jwk value is malformed" do
          let(:public_key_in_jwk) { { kty: Auth::DpopTokenHelper::VALID_KTY } }

          it 'raises DpopValidationError' do
            expect do
              validate!
            end.to raise_error(Gitlab::Auth::DpopValidationError,
              /Key format is invalid for RSA/)
          end
        end

        context "when the jwk value is invalid" do
          let(:public_key_in_jwk) { { kty: Auth::DpopTokenHelper::VALID_KTY, n: '', e: '' } }

          it 'raises DpopValidationError' do
            expect do
              validate!
            end.to raise_error(Gitlab::Auth::DpopValidationError,
              /Failed to parse JWK: invalid JWK/)
          end
        end
      end

      context 'when the access token hash is incorrect' do
        let(:ath) { 'incorrect' }

        it 'raises DpopValidationError' do
          expect do
            validate!
          end.to raise_error(Gitlab::Auth::DpopValidationError,
            /Incorrect access token hash in JWT/)
        end
      end
    end
  end
end
