# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BroadcastMessageDismissal, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }
  let_it_be(:message_1) { create(:broadcast_message, :future) }
  let_it_be(:message_2) { create(:broadcast_message, :future) }
  let_it_be(:message_3) { create(:broadcast_message, :future) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:broadcast_message) }
  end

  describe 'validations' do
    subject { build(:broadcast_message_dismissal, user: user, broadcast_message: message_1) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:broadcast_message) }
    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:broadcast_message_id) }
  end

  describe 'scopes' do
    let_it_be(:expired_dismissal) do
      create(:broadcast_message_dismissal, :expired, user: user, broadcast_message: message_1)
    end

    let_it_be(:valid_dismissal_1) do
      create(:broadcast_message_dismissal, :future, user: user, broadcast_message: message_2)
    end

    let_it_be(:valid_dismissal_2) do
      create(:broadcast_message_dismissal, :future, user: user, broadcast_message: message_3)
    end

    describe '.valid_dismissals' do
      it 'only returns valid dismissals' do
        expect(described_class.valid_dismissals).to match_array([valid_dismissal_1, valid_dismissal_2])
      end
    end

    describe '.for_user_and_broadcast_message' do
      let_it_be(:user_2) { create(:user) }
      let_it_be(:other_dismissal) do
        create(:broadcast_message_dismissal, :future, user: user_2, broadcast_message: message_1)
      end

      it 'only returns correct dismissals' do
        user_message_ids = [message_3.id]
        user_2_message_ids = [message_1.id, message_2.id]

        expect(described_class.for_user_and_broadcast_message(user, user_message_ids)).to match_array valid_dismissal_2

        expect(described_class.for_user_and_broadcast_message(user_2,
          user_2_message_ids)).to match_array other_dismissal
      end
    end
  end

  describe '.find_or_initialize_dismissal' do
    let_it_be(:message) { create(:broadcast_message, :future) }
    let_it_be(:user) { create(:user) }

    subject { described_class.find_or_initialize_dismissal(user, message) }

    context 'when the dismissal does not exists' do
      it { is_expected.to be_a_new_record }
    end

    context 'when the dismissal exists' do
      let_it_be(:existing_dismissal) do
        create(:broadcast_message_dismissal, :future, user: user, broadcast_message: message)
      end

      it { is_expected.to eq(existing_dismissal) }
    end
  end

  describe '.cookie_key' do
    let_it_be(:dismissal) do
      create(:broadcast_message_dismissal, :future, user: user, broadcast_message: message_1)
    end

    it 'returns the correct cookie key' do
      expect(dismissal.cookie_key).to eq "hide_broadcast_message_#{message_1.id}"
    end
  end

  describe '.get_cookie_key' do
    it 'returns the correct cookie key' do
      expect(described_class.get_cookie_key(message_1.id)).to eq "hide_broadcast_message_#{message_1.id}"
    end
  end
end
