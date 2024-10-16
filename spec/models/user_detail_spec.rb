# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserDetail, feature_category: :system_access do
  it { is_expected.to belong_to(:user) }

  specify do
    values = [:basics, :move_repository, :code_storage, :exploring, :ci, :other, :joining_team]
    is_expected.to define_enum_for(:registration_objective).with_values(values).with_suffix
  end

  describe 'validations' do
    context 'for onboarding_status json schema' do
      let(:step_url) { '_some_string_' }
      let(:email_opt_in) { true }
      let(:registration_type) { 'free' }
      let(:onboarding_status) do
        {
          step_url: step_url,
          email_opt_in: email_opt_in,
          initial_registration_type: registration_type,
          registration_type: registration_type
        }
      end

      it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

      context 'for step_url' do
        let(:onboarding_status) do
          {
            step_url: step_url
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'step_url' is invalid" do
          let(:step_url) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for email_opt_in' do
        let(:onboarding_status) do
          {
            email_opt_in: email_opt_in
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'email_opt_in' is invalid" do
          let(:email_opt_in) { 'true' }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for initial_registration_type' do
        let(:onboarding_status) do
          {
            initial_registration_type: registration_type
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'initial_registration_type' is invalid" do
          let(:registration_type) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for registration_type' do
        let(:onboarding_status) do
          {
            registration_type: registration_type
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'registration_type' is invalid" do
          let(:registration_type) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'when there is no data' do
        let(:onboarding_status) { {} }

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }
      end

      context 'when trying to store an unsupported key' do
        let(:onboarding_status) do
          {
            unsupported_key: '_some_value_'
          }
        end

        it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
      end
    end

    describe '#job_title' do
      it { is_expected.not_to validate_presence_of(:job_title) }
      it { is_expected.to validate_length_of(:job_title).is_at_most(200) }
    end

    describe '#pronouns' do
      it { is_expected.not_to validate_presence_of(:pronouns) }
      it { is_expected.to validate_length_of(:pronouns).is_at_most(50) }
    end

    describe '#pronunciation' do
      it { is_expected.not_to validate_presence_of(:pronunciation) }
      it { is_expected.to validate_length_of(:pronunciation).is_at_most(255) }
    end

    describe '#bio' do
      it { is_expected.to validate_length_of(:bio).is_at_most(255) }
    end

    describe '#linkedin' do
      it { is_expected.to validate_length_of(:linkedin).is_at_most(500) }
    end

    describe '#twitter' do
      it { is_expected.to validate_length_of(:twitter).is_at_most(500) }
    end

    describe '#skype' do
      it { is_expected.to validate_length_of(:skype).is_at_most(500) }
    end

    describe '#discord' do
      it { is_expected.to validate_length_of(:discord).is_at_most(500) }

      context 'when discord is set' do
        let_it_be(:user_detail) { create(:user_detail) }

        it 'accepts a valid discord user id' do
          user_detail.discord = '1234567890123456789'

          expect(user_detail).to be_valid
        end

        it 'throws an error when other url format is wrong' do
          user_detail.discord = '123456789'

          expect(user_detail).not_to be_valid
          expect(user_detail.errors.full_messages).to match_array([_('Discord must contain only a discord user ID.')])
        end
      end
    end

    describe '#mastodon' do
      it { is_expected.to validate_length_of(:mastodon).is_at_most(500) }

      context 'when mastodon is set' do
        let_it_be(:user_detail) { create(:user_detail) }

        it 'accepts a valid mastodon username' do
          user_detail.mastodon = '@robin@example.com'

          expect(user_detail).to be_valid
        end

        it 'throws an error when mastodon username format is wrong' do
          user_detail.mastodon = '@robin'

          expect(user_detail).not_to be_valid
          expect(user_detail.errors.full_messages)
            .to match_array([_('Mastodon must contain only a mastodon username.')])
        end
      end
    end

    describe '#location' do
      it { is_expected.to validate_length_of(:location).is_at_most(500) }
    end

    describe '#organization' do
      it { is_expected.to validate_length_of(:organization).is_at_most(500) }
    end

    describe '#website_url' do
      it { is_expected.to validate_length_of(:website_url).is_at_most(500) }

      it 'only validates the website_url if it is changed' do
        user_detail = create(:user_detail)
        # `update_attribute` required to bypass current validations
        # Validations on `User#website_url` were added after
        # there was already data in the database and `UserDetail#website_url` is
        # derived from `User#website_url` so this reproduces the state of some of
        # our production data
        user_detail.update_attribute(:website_url, 'NotAUrl')

        expect(user_detail).to be_valid

        user_detail.website_url = 'AlsoNotAUrl'

        expect(user_detail).not_to be_valid
        expect(user_detail.errors.full_messages).to match_array(["Website url is not a valid URL"])
      end
    end
  end

  describe '#save' do
    let(:user_detail) do
      create(
        :user_detail,
        bio: 'bio',
        discord: '1234567890123456789',
        linkedin: 'linkedin',
        location: 'location',
        mastodon: '@robin@example.com',
        organization: 'organization',
        skype: 'skype',
        twitter: 'twitter',
        website_url: 'https://example.com'
      )
    end

    shared_examples 'prevents `nil` value' do |attr|
      it 'converts `nil` to the empty string' do
        user_detail[attr] = nil
        expect { user_detail.save! }
          .to change { user_detail[attr] }.to('')
          .and not_change { user_detail.attributes.except(attr.to_s) }
      end
    end

    it_behaves_like 'prevents `nil` value', :bio
    it_behaves_like 'prevents `nil` value', :discord
    it_behaves_like 'prevents `nil` value', :linkedin
    it_behaves_like 'prevents `nil` value', :location
    it_behaves_like 'prevents `nil` value', :mastodon
    it_behaves_like 'prevents `nil` value', :organization
    it_behaves_like 'prevents `nil` value', :skype
    it_behaves_like 'prevents `nil` value', :twitter
    it_behaves_like 'prevents `nil` value', :website_url
  end

  describe '#sanitize_attrs' do
    shared_examples 'sanitizes html' do |attr|
      it 'sanitizes html tags' do
        details = build_stubbed(:user_detail, attr => '<a href="//evil.com">https://example.com<a>')
        expect { details.sanitize_attrs }.to change { details[attr] }.to('https://example.com')
      end

      it 'sanitizes iframe scripts' do
        details = build_stubbed(:user_detail, attr => '<iframe src=javascript:alert()><iframe>')
        expect { details.sanitize_attrs }.to change { details[attr] }.to('')
      end

      it 'sanitizes js scripts' do
        details = build_stubbed(:user_detail, attr => '<script>alert("Test")</script>')
        expect { details.sanitize_attrs }.to change { details[attr] }.to('')
      end
    end

    %i[linkedin skype twitter website_url].each do |attr|
      it_behaves_like 'sanitizes html', attr

      it 'encodes HTML entities' do
        details = build_stubbed(:user_detail, attr => 'test&attr')
        expect { details.sanitize_attrs }.to change { details[attr] }.to('test&amp;attr')
      end
    end

    %i[location organization].each do |attr|
      it_behaves_like 'sanitizes html', attr

      it 'does not encode HTML entities' do
        details = build_stubbed(:user_detail, attr => 'test&attr')
        expect { details.sanitize_attrs }.not_to change { details[attr] }
      end
    end

    it 'sanitizes on validation' do
      details = build(:user_detail)

      expect(details)
        .to receive(:sanitize_attrs)
        .at_least(:once)
        .and_call_original

      details.save!
    end
  end
end
