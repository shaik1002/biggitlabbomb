# frozen_string_literal: true

require('spec_helper')

RSpec.describe UserSettings::PasswordsController, feature_category: :system_access do
  describe '#update' do
    context 'when a deactivated user signs-in after an admin resets their password' do
      let(:deactivated_user) { create(:user, :deactivated) }

      let(:password) { User.random_password }
      let(:password_confirmation) { password }
      let(:reset_password_token) { deactivated_user.send_reset_password_instructions }

      subject(:update_password) do
        put :update, params: {
          user: {
            password: password,
            password_confirmation: password_confirmation,
            reset_password_token: reset_password_token
          }
        }
      end

      before do
        sign_in deactivated_user
      end

      it 'allows the deactivated user to update their password' do
        update_password
        expect(response).to redirect_to(edit_user_settings_password_path)
      end
    end
  end
end
